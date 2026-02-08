# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 This decorator is used to override logic found in
module Hyrax
  #
  # Because Hyku has converted the Hyrax::Group model from a PORO to a db-backed active record object,
  # we have to query for existing Hyrax groups instead of initializing empty ones.
  module AdminSetCreateServiceDecorator
    def create!
      # This may need to be contributed back upstream to Hyrax.
      #
      # If we don't nullify this value we get the following error:
      # `primary key column can not save with the given ID admin_set/default`
      admin_set.id = nil if admin_set.id == AdminSetCreateService::DEFAULT_ID
      super
    end

    # OVERRIDE: In baseline Hyrax this method grants deposit access into the Default Admin Set for
    # all registered users.
    def create_default_access_for(*)
      true
    end

    private

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
