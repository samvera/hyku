# frozen_string_literal: true

module Hyrax
  # This decorator is used to override logic found in Hyrax v3.4.2
  #
  # Because Hyku has converted the Hyrax::Group model from a PORO to a db-backed active record object,
  # we have to query for existing Hyrax groups instead of initializing empty ones.
  module AdminSetCreateServiceDecorator
    # Creates an admin set, setting the creator and the default access controls.
    # @return [Hyrax::AdministrativeSet] The fully created admin set.
    # @raise [RuntimeError] if admin set cannot be persisted
    def create!
      admin_set.creator = [creating_user.user_key] if creating_user
      updated_admin_set = Hyrax.persister.save(resource: admin_set).tap do |result|
        if result
          ActiveRecord::Base.transaction do
            permission_template = PermissionTemplate.find_by(source_id: result.id.to_s) ||
                                  permissions_create_service.create_default(collection: result,
                                                                            creating_user:)
            create_workflows_for(permission_template:)
            # OVERRIDE: Remove call to #create_default_access_for, which granted
            # deposit access to all registered users for the Default Admin Set
          end
        end
      end
      Hyrax.publisher.publish('collection.metadata.updated', collection: updated_admin_set, user: creating_user)
      updated_admin_set
    end

    def workflow_agents
      [
        # OVERRIDE: replace #new with #find_by(:name)
        Hyrax::Group.find_by(name: admin_group_name)
      ].tap do |agent_list|
        # The default admin set does not have a creating user
        agent_list << creating_user if creating_user
      end
    end

    def create_workflows_for(permission_template:)
      workflow_importer.call(permission_template:)
      # OVERRIDE: Extract and expand upon granting Workflow Roles into service object so it can be used in RolesService
      Hyrax::Workflow::PermissionGrantor
        .grant_default_workflow_roles!(permission_template:, creating_user:)
      Sipity::Workflow
        .activate!(permission_template:, workflow_name: Hyrax.config.default_active_workflow_name)
    end
  end
end

Hyrax::AdminSetCreateService.prepend(Hyrax::AdminSetCreateServiceDecorator)
