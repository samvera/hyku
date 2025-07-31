# frozen_string_literal: true

module Sample
  class ActiveFedoraService # rubocop:disable Metrics/ClassLength
    include SharedMethods

    def create_sample_data
      validate_and_switch_tenant
      load_sample_data
      setup_dependencies
      begin
        setup_job_configuration
        ENV['HYRAX_VALKYRIE'] = 'false'
        Hyrax.config.use_valkyrie = false

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

      Rails.logger.debug "Removing all sample data from tenant '#{tenant_name}'..."

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

    def setup_dependencies
      @user = User.first
      Rails.logger.debug "Creating #{quantity} sample Active Fedora works for tenant '#{tenant_name}'..."
    end

    def create_collections(count)
      Rails.logger.debug "Creating Collections..."
      default_collection_type = Hyrax::CollectionType.find_or_create_default_collection_type
      collections = []

      (1..count).each do |i|
        collection = build_collection(i, default_collection_type)
        Sample::PermissionTemplateService.create_for_collection(collection, user)
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
        image = build_work(Image, i, "Image")
        add_to_random_collection(image, collections)
        image.save!

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
        work = build_work(GenericWork, i, "Generic Work")
        add_to_random_collection(work, collections)
        work.save!

        file_path = select_file_for_work(i)
        attach_file_to_work(work, file_path)
        generic_works << work
        Rails.logger.debug "."
      end

      Rails.logger.debug "\nCreated #{generic_works.length} generic works with file attachments."
      generic_works
    end

    def build_collection(index, collection_type) # rubocop:disable Metrics/AbcSize
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

    def build_work(work_class, index, type_name) # rubocop:disable Metrics/AbcSize
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
      Rails.logger.debug "Indexing all works in Solr..."
      works.each do |work|
        work.update_index
        Rails.logger.debug "."
      end
      Rails.logger.debug "\nIndexing complete!"
    end

    def clean_works_by_pattern(model_class, pattern)
      count = 0
      model_class.where("title_tesim:#{pattern}").find_each do |work|
        work.destroy
        count += 1
        Rails.logger.debug "."
      end
      count
    end
  end
end
