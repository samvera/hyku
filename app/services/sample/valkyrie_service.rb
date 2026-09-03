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
        works_by_type = work_type_counts.to_h do |type_name, count|
          [type_name, create_works_of_type(type_name, count, collections)]
        end

        all_works = works_by_type.values.flatten
        total_works = collections.length + all_works.length

        index_all_works(collections + all_works)

        counts = { 'Collections' => collections.length }
        works_by_type.each { |type_name, works| counts[work_type_label(type_name)] = works.length }
        print_completion_summary(counts, total_works)
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

        # Driven by the same type list as creation, so cleanup cannot orphan a
        # work type that seeding created.
        counts = { 'Collections' => clean_works_by_pattern(CollectionResource, "%CollectionResource %:%") }
        work_type_counts.each_key do |type_name|
          klass = work_class_for(type_name)
          counts[work_type_label(type_name)] = clean_works_by_pattern(klass, "%#{klass.name} %:%")
        end
        counts['FileSets'] = clean_works_by_pattern(Hyrax::FileSet, "%Hyrax::FileSet %:%")

        total_removed = counts.values.sum
        print_cleanup_summary(counts, total_removed)
      ensure
        Hyrax.config.use_valkyrie = @original_use_valkyrie
      end
    end

    private

    def random_visibility
      visibility_pool.sample
    end

    # 80% public / 15% authenticated / 5% private by default, so access-control checks have real variety to chew on.
    def visibility_pool
      @visibility_pool ||= [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC] * ENV.fetch('HYKU_SAMPLE_VISIBILITY_PUBLIC', 80).to_i +
                           [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED] * ENV.fetch('HYKU_SAMPLE_VISIBILITY_AUTHENTICATED', 15).to_i +
                           [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE] * ENV.fetch('HYKU_SAMPLE_VISIBILITY_PRIVATE', 5).to_i
    end

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

    def create_works_of_type(type_name, count, collections)
      label = work_type_label(type_name)
      Rails.logger.debug "Creating #{label}..."
      resource_class = work_class_for(type_name)
      works = []

      (1..count).each do |i|
        work = build_work(resource_class, i, resource_class.name)
        add_to_random_collection(work, collections)

        # Images get an image; everything else cycles the sample file types.
        file_path = type_name == 'Image' ? sample_data[:files][:image].first : select_file_for_work(i)
        attach_file_to_work(work, file_path)
        works << work
        Rails.logger.debug "."
      end

      Rails.logger.debug "\nCreated #{works.length} #{label.downcase} with file attachments."
      works
    end

    def work_class_for(type_name)
      "#{type_name}Resource".safe_constantize ||
        raise(ArgumentError, "No Valkyrie resource class for work type '#{type_name}'")
    end

    def build_collection(index, collection_type) # rubocop:disable Metrics/AbcSize
      collection_attrs = {
        title: ["CollectionResource #{index}: #{sample_data[:titles][index % sample_data[:titles].length]}"],
        description: sample_data[:descriptions][index % sample_data[:descriptions].length],
        creator: sample_data[:creators][index % sample_data[:creators].length],
        subject: sample_data[:subjects][index % sample_data[:subjects].length],
        collection_type_gid: collection_type.to_global_id.to_s,
        depositor: user.user_key
      }

      collection = Hyrax.persister.save(resource: CollectionResource.new(collection_attrs))
      apply_visibility(collection)
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
        bulkrax_identifier: "SampleValk-#{work_class}#{index}",
        depositor: user.user_key,
        admin_set_id: admin_set.id
      }

      work = Hyrax.persister.save(resource: work_class.new(work_attrs))
      apply_visibility(work)
      Hyrax.index_adapter.save(resource: work)
      Hyrax.publisher.publish('object.deposited', object: work, user: user)
      Hyrax.publisher.publish('object.metadata.updated', object: work, user: user)
      work
    end

    # Valkyrie resource constructors silently discard a :visibility key
    # because visibility is not a Valkyrie attribute. It has to be assigned
    # through the resource's visibility writer once the resource has an id,
    # and the resulting ACL has to be persisted as its own resource.
    def apply_visibility(resource)
      return resource if visibility.blank?

      resource.visibility = visibility
      resource.permission_manager.acl.save
      resource
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
