# frozen_string_literal: true

module Sample
  class ActiveFedoraService
    attr_reader :tenant_name, :sample_files_dir, :sample_data, :user, :quantity

    def initialize(tenant_name, quantity = 50)
      @tenant_name = tenant_name
      @quantity = quantity.to_i
      @sample_files_dir = Rails.root.join('db', 'seeds', 'sample')
      @sample_data = {}
      @user = nil
    end

    def create_sample_data
      validate_and_switch_tenant
      load_sample_data
      setup_dependencies
      begin
        @original_use_valkyrie = Hyrax.config.use_valkyrie?
        ENV['HYRAX_VALKYRIE'] = 'false'
        Hyrax.config.use_valkyrie = false
        @original_hyrax_queue = ENV['HYRAX_ACTIVE_JOB_QUEUE']
        ENV['HYRAX_ACTIVE_JOB_QUEUE'] = 'async'
        @original_queue_adapter = ActiveJob::Base.queue_adapter
        ActiveJob::Base.queue_adapter = ActiveJob::QueueAdapters::AsyncAdapter.new

        collections = create_collections(quantity)
        images = create_images(quantity, collections)
        generic_works = create_generic_works(quantity, collections)

        total_works = collections.length + images.length + generic_works.length

        index_all_works(collections + images + generic_works)

        print_completion_summary(collections, images, generic_works, total_works)
      ensure
        Hyrax.config.use_valkyrie = @original_use_valkyrie
        ENV['HYRAX_VALKYRIE'] = @original_use_valkyrie.to_s
        ActiveJob::Base.queue_adapter = @original_queue_adapter
      end
    end

    def clean_sample_data
      validate_and_switch_tenant

      return unless confirm_cleanup

      puts "Removing all sample data from tenant '#{tenant_name}'..."

      counts = {
        collections: clean_works_by_pattern(Collection, "%Collection %:%"),
        images: clean_works_by_pattern(Image, "%Image %:%"),
        generic_works: clean_works_by_pattern(GenericWork, "%Generic Work %:%"),
        file_sets: clean_works_by_pattern(FileSet, "%FileSet %:%")
      }

      total_removed = counts.values.sum
      print_cleanup_summary(counts, total_removed)
    end

    private

    def confirm_cleanup
      # Skip confirmation if CONFIRM environment variable is set to 'true'
      return true if ENV['CONFIRM']&.downcase == 'true'

      puts "\n" + "=" * 60
      puts "WARNING: DESTRUCTIVE OPERATION"
      puts "=" * 60
      puts "This will DELETE works, collections, and file sets from tenant '#{tenant_name}'"
      puts "that match the following title patterns:"
      puts "  - Collections with titles like 'Collection N: ...'"
      puts "  - Images with titles like 'Image N: ...'"
      puts "  - Generic Works with titles like 'Generic Work N: ...'"
      puts "  - File Sets with titles like 'FileSet N: ...'"
      puts "\nThis action CANNOT be undone!"
      puts "=" * 60
      print "\nType 'yes' to continue or anything else to abort: "

      response = $stdin.gets.chomp
      confirmed = response.downcase == 'yes'

      unless confirmed
        puts "Operation aborted."
        return false
      end

      puts "Proceeding with cleanup..."
      true
    end

    def validate_and_switch_tenant
      account = Account.find_by(name: tenant_name)
      if account.nil?
        puts "ERROR: Tenant '#{tenant_name}' not found!"
        puts "Available tenants:"
        Account.all.each { |acc| puts "  - #{acc.name}" }
        exit 1
      end

      puts "Switching to tenant: #{tenant_name}"
      AccountElevator.switch!(tenant_name)
    end

    def load_sample_data
      require 'csv'

      puts "Loading sample data from CSV files..."
      @sample_data = {
        titles: CSV.read(sample_files_dir.join('sample_titles.csv'), headers: true)['title'],
        descriptions: CSV.read(sample_files_dir.join('sample_descriptions.csv'), headers: true)['description'],
        creators: CSV.read(sample_files_dir.join('sample_creators.csv'), headers: true)['creator'].map { |creator| [creator] },
        subjects: load_subjects_from_csv,
        files: {
          pdf: ['sample-report.pdf'],
          image: ['landscape_hires_4000x2667_6.83mb.jpg'],
          audio: ['mp3_44100Hz_128kbps_stereo.mp3', 'm4a_48000Hz_256kbps_stereo.m4a'],
          video: ['big_buck_bunny_720p_10mb.mp4']
        }
      }

      puts "Using sample files:"
      @sample_data[:files].each do |type, files|
        puts "  #{type.upcase}: #{files.join(', ')}"
      end

      puts "Loaded #{@sample_data[:titles].length} titles, #{@sample_data[:descriptions].length} descriptions, #{@sample_data[:creators].length} creators, #{@sample_data[:subjects].length} subject sets"
      puts
    end

    def load_subjects_from_csv
      subjects_csv = CSV.read(sample_files_dir.join('sample_subjects.csv'), headers: true)
      subjects_csv.map do |row|
        [row['subject1'], row['subject2'], row['subject3']].compact.reject(&:empty?)
      end
    end

    def setup_dependencies
      @user = User.first
      puts "Creating #{quantity} sample Active Fedora works for tenant '#{tenant_name}'..."
    end

    def create_collections(count)
      puts "Creating Collections..."
      default_collection_type = Hyrax::CollectionType.find_or_create_default_collection_type
      collections = []

      (1..count).each do |i|
        collection = build_collection(i, default_collection_type)
        Sample::PermissionTemplateService.create_for_collection(collection, user)
        collections << collection
        print "."
      end

      puts "\nCreated #{collections.length} collections."
      collections
    end

    def create_images(count, collections)
      puts "Creating Images..."
      images = []

      (1..count).each do |i|
        image = build_work(Image, i, "Image")
        add_to_random_collection(image, collections)
        image.save!

        attach_file_to_work(image, sample_data[:files][:image].first)
        images << image
        print "."
      end

      puts "\nCreated #{images.length} images with file attachments."
      images
    end

    def create_generic_works(count, collections)
      puts "Creating Generic Works..."
      generic_works = []

      (1..count).each do |i|
        work = build_work(GenericWork, i, "Generic Work")
        add_to_random_collection(work, collections)
        work.save!

        file_path = select_file_for_work(i)
        attach_file_to_work(work, file_path)
        generic_works << work
        print "."
      end

      puts "\nCreated #{generic_works.length} generic works with file attachments."
      generic_works
    end

    def build_collection(index, collection_type)
      collection = Collection.new(
        title: ["Collection #{index}: #{sample_data[:titles][index % sample_data[:titles].length]}"],
        description: [sample_data[:descriptions][index % sample_data[:descriptions].length]],
        creator: sample_data[:creators][index % sample_data[:creators].length],
        subject: sample_data[:subjects][index % sample_data[:subjects].length],
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
        collection_type_gid: collection_type.to_global_id.to_s
      )
      collection.apply_depositor_metadata(user.user_key)
      collection.save!
      collection
    end

    def build_work(work_class, index, type_name)
      work = work_class.new(
        title: ["#{type_name} #{index}: #{sample_data[:titles][index % sample_data[:titles].length]}"],
        description: [sample_data[:descriptions][index % sample_data[:descriptions].length]],
        creator: sample_data[:creators][index % sample_data[:creators].length],
        subject: sample_data[:subjects][index % sample_data[:subjects].length],
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      )
      work.apply_depositor_metadata(user.user_key)
      work
    end

    def add_to_random_collection(work, collections)
      return unless collections.any?

      collection = collections.sample
      work.member_of_collections << collection
    end

    def select_file_for_work(index)
      case index % 4
      when 0 then sample_data[:files][:pdf].first
      when 1 then sample_data[:files][:image].first
      when 2 then sample_data[:files][:audio].sample
      when 3 then sample_data[:files][:video].first
      end
    end

    def attach_file_to_work(work, filename)
      file_set = FileSet.new
      file_set.save!

      uploaded_file = Hyrax::UploadedFile.create(
        file: File.open(sample_files_dir.join(filename)),
        user: user
      )

      AttachFilesToWorkJob.perform_now(work, [uploaded_file])
      work.save!
    end

    def index_all_works(works)
      puts "Indexing all works in Solr..."
      works.each do |work|
        work.update_index
        print "."
      end
      puts "\nIndexing complete!"
    end

    def clean_works_by_pattern(model_class, pattern)
      count = 0
      model_class.where("title_tesim:#{pattern}").find_each do |work|
        work.destroy
        count += 1
        print "."
      end
      count
    end

    def print_completion_summary(collections, images, generic_works, total)
      puts "\n" + "=" * 60
      puts "SAMPLE DATA CREATION COMPLETE"
      puts "=" * 60
      puts "Tenant: #{tenant_name}"
      puts "Created #{collections.length} Collections"
      puts "Created #{images.length} Images"
      puts "Created #{generic_works.length} Generic Works"
      puts "Total: #{total} works created"
      puts "=" * 60
    end

    def print_cleanup_summary(counts, total)
      puts "\n" + "=" * 60
      puts "SAMPLE DATA CLEANUP COMPLETE"
      puts "=" * 60
      puts "Tenant: #{tenant_name}"
      puts "Removed #{counts[:collections]} Collections"
      puts "Removed #{counts[:images]} Images"
      puts "Removed #{counts[:generic_works]} Generic Works"
      puts "Removed #{counts[:file_sets]} FileSets"
      puts "Total: #{total} works removed"
      puts "=" * 60
    end
  end
end
