# frozen_string_literal: true

module Sample
  class ActiveFedoraService # rubocop:disable Metrics/ClassLength
    include SharedMethods

    def create_sample_data # rubocop:disable Metrics/AbcSize
      validate_and_switch_tenant
      load_sample_data
      setup_dependencies
      begin
        setup_job_configuration
        Hydra::Derivatives.config.output_file_service = Hyrax::PersistDerivatives
        ENV['HYRAX_VALKYRIE'] = 'false'
        Hyrax.config.use_valkyrie = false

        # we have to create the admin set after we switch modes
        self.admin_set = find_or_create_admin_set
        collections = create_collections(quantity)
        images = create_images(quantity, collections)
        generic_works = create_generic_works(quantity, collections)
        oers = create_oers(quantity, collections)
        total_works = collections.length + images.length + generic_works.length + oers.length

        index_all_works(collections + images + generic_works + oers)

        print_completion_summary(collections, images, generic_works, oers, total_works)
      ensure
        Hydra::Derivatives.config.output_file_service = Hyrax::ValkyriePersistDerivatives
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
      self.user = User.first
      Rails.logger.debug "Creating #{quantity} sample Active Fedora works for tenant '#{tenant_name}'..."
    end

    def find_or_create_admin_set
      admin_set = AdminSet.where(id: AdminSet::DEFAULT_ID)&.first
      return admin_set if admin_set.present?
      admin_set = AdminSet.new(id: AdminSet::DEFAULT_ID, title: Array.wrap('Fedora Sample Admin Set'))
      admin_set.creator = [user.user_key] if user
      admin_set.save.tap do |result|
        if result
          ActiveRecord::Base.transaction do
            permission_template = create_permission_template(admin_set)
            workflow = create_workflows_for(permission_template: permission_template)
            create_default_access_for(permission_template: permission_template, workflow: workflow)
          end
        end
      end
      admin_set
    end

    def access_grants_attributes
      [
        { agent_type: 'group', agent_id: admin_group_name, access: Hyrax::PermissionTemplateAccess::MANAGE }
      ].tap do |attribute_list|
        # Grant manage access to the user if it exists. Should exist for all but default Admin Set
        attribute_list << { agent_type: 'user', agent_id: user.user_key, access: Hyrax::PermissionTemplateAccess::MANAGE } if user
      end
    end

    def admin_group_name
      ::Ability.admin_group_name
    end

    def create_permission_template(admin_set)
      permission_template = Hyrax::PermissionTemplate.create!(source_id: admin_set.id, access_grants_attributes: access_grants_attributes)
      permission_template.reset_access_controls_for(collection: admin_set, interpret_visibility: true)
      permission_template
    end

    def create_workflows_for(permission_template:)
      Hyrax::Workflow::WorkflowImporter.method(:load_workflow_for).call(permission_template: permission_template)
      grant_all_workflow_roles_to_creating_user_and_admins!(permission_template: permission_template)
      Sipity::Workflow.activate!(permission_template: permission_template, workflow_name: Hyrax.config.default_active_workflow_name)
    end

    # Force creation of registered MANAGING role if it doesn't exist
    def register_managing_role!
      Sipity::Role[Hyrax::RoleRegistry::MANAGING]
    end

    def grant_all_workflow_roles_to_creating_user_and_admins!(permission_template:)
      # This code must be invoked before calling `Sipity::Role.all` or the managing role won't be there
      register_managing_role!
      # Grant all workflow roles to the creating_user and the admin group
      permission_template.available_workflows.each do |workflow|
        Sipity::Role.find_each do |role|
          workflow.update_responsibilities(role: role,
                                           agents: workflow_agents)
        end
      end
    end

    def workflow_agents
      [
        Hyrax::Group.new(admin_group_name)
      ].tap do |agent_list|
        # The default admin set does not have a creating user
        agent_list << user if user
      end
    end

    # Gives deposit access to registered users to default AdminSet
    def create_default_access_for(permission_template:, workflow:)
      permission_template.access_grants.create(agent_type: 'group', agent_id: ::Ability.registered_group_name, access: Hyrax::PermissionTemplateAccess::DEPOSIT)
      deposit = Sipity::Role[Hyrax::RoleRegistry::DEPOSITING]
      workflow.update_responsibilities(role: deposit, agents: Hyrax::Group.new('registered'))
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

    def create_oers(count, collections) # rubocop:disable Metrics/AbcSize
      Rails.logger.debug "Creating OERs..."
      oers = []

      (1..count).each do |index|
        oer = begin
          work = Oer.new(
          title: ["Oer Sample #{index}: #{sample_data[:titles][index % sample_data[:titles].length]}"],
          description: [sample_data[:descriptions][index % sample_data[:descriptions].length]],
          creator: sample_data[:creators][index % sample_data[:creators].length],
          subject: sample_data[:subjects][index % sample_data[:subjects].length],
          bulkrax_identifier: "SampleOer#{index}",
          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          admin_set: admin_set,
          resource_type: ['Other'],
          audience: ['Higher Education'],
          education_level: ['College'],
          learning_resource_type: ['Textbook'],
          discipline: ['History']
        )
          work.apply_depositor_metadata(user.user_key)
          work
        end
        add_to_random_collection(oer, collections)
        oer.save!

        file_path = select_file_for_work(index)
        attach_file_to_work(work, file_path)
        oers << oer
        Rails.logger.debug "."
      end

      Rails.logger.debug "\nCreated #{oers.length} OERs with file attachments."
      oers
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
        bulkrax_identifier: "Sample#{work_class}#{index}",
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
        admin_set: admin_set
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
