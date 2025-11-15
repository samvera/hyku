# frozen_string_literal: true

require_relative 'shared_methods'

module Sample
  class ValkyrieService # rubocop:disable Metrics/ClassLength
    include SharedMethods

    def create_sample_data # rubocop:disable Metrics/AbcSize
      validate_and_switch_tenant
      load_sample_data
      setup_dependencies

      begin
        setup_job_configuration
        ENV['HYRAX_VALKYRIE'] = 'true'
        Hyrax.config.use_valkyrie = true

        # we have to create the admin set after we switch modes
        self.admin_set = find_or_create_admin_set
        collections = create_collections(quantity)
        images = create_images(quantity, collections)
        generic_works = create_generic_works(quantity, collections)

        total_works = collections.length + images.length + generic_works.length

        index_all_works(collections + images + generic_works)

        print_completion_summary(collections, images, generic_works, total_works)
      ensure
        restore_job_configuration
      end
    end

    def clean_sample_data
      validate_and_switch_tenant

      return unless confirm_cleanup

      Rails.logger.debug "Removing all sample Valkyrie data from tenant '#{tenant_name}'..."

      begin
        @original_use_valkyrie = Hyrax.config.use_valkyrie?
        Hyrax.config.use_valkyrie = true

        counts = {
          collections: clean_works_by_pattern(CollectionResource, "%CollectionResource %:%"),
          images: clean_works_by_pattern(ImageResource, "%ImageResource %:%"),
          generic_works: clean_works_by_pattern(GenericWorkResource, "%GenericWorkResource %:%"),
          file_sets: clean_works_by_pattern(Hyrax::FileSet, "%Hyrax::FileSet %:%")
        }

        total_removed = counts.values.sum
        print_cleanup_summary(counts, total_removed)
      ensure
        Hyrax.config.use_valkyrie = @original_use_valkyrie
      end
    end

    private

    def confirm_cleanup # rubocop:disable Metrics/AbcSize
      # Skip confirmation if CONFIRM environment variable is set to 'true'
      return true if ENV['CONFIRM']&.downcase == 'true'

      Rails.logger.debug "\n" + "=" * 60
      Rails.logger.debug "WARNING: DESTRUCTIVE OPERATION"
      Rails.logger.debug "=" * 60
      Rails.logger.debug "This will DELETE Valkyrie works, collections, and file sets from tenant '#{tenant_name}'"
      Rails.logger.debug "that match the following title patterns:"
      Rails.logger.debug "  - Collections with titles like 'Collection N: ...'"
      Rails.logger.debug "  - Images with titles like 'Image N: ...'"
      Rails.logger.debug "  - Generic Works with titles like 'Generic Work N: ...'"
      Rails.logger.debug "  - File Sets with titles like 'FileSet N: ...'"
      Rails.logger.debug "\nThis action CANNOT be undone!"
      Rails.logger.debug "=" * 60
      Rails.logger.debug "\nType 'yes' to continue or anything else to abort: "

      response = $stdin.gets.chomp
      confirmed = response.casecmp('yes').zero?

      unless confirmed
        Rails.logger.debug "Operation aborted."
        return false
      end

      Rails.logger.debug "Proceeding with cleanup..."
      true
    end

    def validate_and_switch_tenant
      account = Account.find_by(name: tenant_name)
      if account.nil?
        Rails.logger.debug "ERROR: Tenant '#{tenant_name}' not found!"
        Rails.logger.debug "Available tenants:"
        Account.find_each { |acc| Rails.logger.debug "  - #{acc.name}" }
        raise 'Tenant not found'
      end

      Rails.logger.debug "Switching to tenant: #{tenant_name}"
      AccountElevator.switch!(tenant_name)
    end

    def load_sample_data # rubocop:disable Metrics/AbcSize
      require 'csv'

      Rails.logger.debug "Loading sample data from CSV files..."
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

      Rails.logger.debug "Using sample files:"
      @sample_data[:files].each do |type, files|
        Rails.logger.debug "  #{type.upcase}: #{files.join(', ')}"
      end

      output = [
        "Loaded #{@sample_data[:titles].length} titles",
        "#{@sample_data[:descriptions].length} descriptions",
        "#{@sample_data[:creators].length} creators",
        "#{@sample_data[:subjects].length} subject sets"
      ]
      Rails.logger.debug output.join(', ')
    end

    def load_subjects_from_csv
      subjects_csv = CSV.read(sample_files_dir.join('sample_subjects.csv'), headers: true)
      subjects_csv.map do |row|
        [row['subject1'], row['subject2'], row['subject3']].compact.reject(&:empty?)
      end
    end

    def setup_dependencies
      @user = User.first
      Rails.logger.debug "Creating #{quantity} sample Valkyrie resources for tenant '#{tenant_name}'..."
    end

    def find_or_create_admin_set
      admin_set_id = 'sample_admin_set'
      Hyrax.query_service.find_by(id: admin_set_id)
    rescue Valkyrie::Persistence::ObjectNotFoundError

      admin_set = Hyrax.config.admin_set_class.new(id: admin_set_id, title: 'Sample Admin Set')
      admin_set_result = Hyrax::AdminSetCreateService.call!(admin_set: admin_set, creating_user: @user)
      admin_set_result
    end

    def create_collections(count)
      Rails.logger.debug "Creating Collections..."
      default_collection_type = Hyrax::CollectionType.find_or_create_default_collection_type
      collections = []

      (1..count).each do |i|
        collection = build_collection(i, default_collection_type)
        collections << collection
        Rails.logger.debug "."
      end

      Rails.logger.debug "\nCreated #{collections.length} collections."
      collections
    end

    def create_images(count, collections)
      Rails.logger.debug "Creating Images..."
      images = []

      (1..count).each do |i|
        image = build_work(ImageResource, i, "ImageResource")
        add_to_random_collection(image, collections)

        attach_file_to_work(image, sample_data[:files][:image].first)
        images << image
        Rails.logger.debug "."
      end

      Rails.logger.debug "\nCreated #{images.length} images with file attachments."
      images
    end

    def create_generic_works(count, collections)
      Rails.logger.debug "Creating Generic Works..."
      generic_works = []

      (1..count).each do |i|
        work = build_work(GenericWorkResource, i, "GenericWorkResource")
        add_to_random_collection(work, collections)

        file_path = select_file_for_work(i)
        attach_file_to_work(work, file_path)
        generic_works << work
        Rails.logger.debug "."
      end

      Rails.logger.debug "\nCreated #{generic_works.length} generic works with file attachments."
      generic_works
    end

    def build_collection(index, collection_type) # rubocop:disable Metrics/AbcSize
      collection_attrs = {
        title: ["CollectionResource #{index}: #{sample_data[:titles][index % sample_data[:titles].length]}"],
        description: sample_data[:descriptions][index % sample_data[:descriptions].length],
        creator: sample_data[:creators][index % sample_data[:creators].length],
        subject: sample_data[:subjects][index % sample_data[:subjects].length],
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
        collection_type_gid: collection_type.to_global_id.to_s,
        depositor: user.user_key
      }

      collection = Hyrax.persister.save(resource: CollectionResource.new(collection_attrs))
      Sample::PermissionTemplateService.create_for_valkyrie_collection(collection, user)
      Hyrax.index_adapter.save(resource: collection)
      Hyrax.publisher.publish('collection.metadata.updated', collection: collection, user: user)

      collection
    end

    def build_work(work_class, index, type_name) # rubocop:disable Metrics/AbcSize
      work_attrs = {
        title: ["#{type_name} #{index}: #{sample_data[:titles][index % sample_data[:titles].length]}"],
        description: sample_data[:descriptions][index % sample_data[:descriptions].length],
        creator: sample_data[:creators][index % sample_data[:creators].length],
        subject: sample_data[:subjects][index % sample_data[:subjects].length],
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
        bulkrax_identifier: "SampleValk-#{work_class}#{index}",
        depositor: user.user_key,
        admin_set_id: admin_set.id
      }

      work = Hyrax.persister.save(resource: work_class.new(work_attrs))
      Hyrax.index_adapter.save(resource: work)
      Hyrax.publisher.publish('object.deposited', object: work, user: user)
      Hyrax.publisher.publish('object.metadata.updated', object: work, user: user)
      work
    end

    def attach_file_to_work(work, filename)
      # Create an uploaded file record for Valkyrie
      uploaded_file = Hyrax::UploadedFile.create(
        file: File.open(sample_files_dir.join(filename)),
        user: user
      )

      # Use Hyrax's file attachment workflow for Valkyrie
      # This will create the file set and handle the attachment properly
      AttachFilesToWorkJob.perform_now(work, [uploaded_file])

      # Ensure the work is re-saved and indexed after file attachment
      work = Hyrax.query_service.find_by(id: work.id)
      Hyrax.persister.save(resource: work)
      Hyrax.index_adapter.save(resource: work)
    end

    def index_all_works(works)
      Rails.logger.debug "Indexing all works in Solr..."
      works.each do |work|
        Hyrax.index_adapter.save(resource: work)
        Rails.logger.debug "."
      end
      Rails.logger.debug "\nIndexing complete!"
    end

    def clean_works_by_pattern(model_class, pattern)
      count = 0
      # For Valkyrie, we need to use the query service
      Hyrax.query_service.find_all_of_model(model: model_class).each do |work|
        next unless work.title.any? { |title| title.match?(Regexp.new(pattern.gsub('%', '.*'))) }
        Hyrax.persister.delete(resource: work)
        Hyrax.index_adapter.delete(resource: work)
        count += 1
        Rails.logger.debug "."
      end
      count
    end
  end
end
