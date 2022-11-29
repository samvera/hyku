# frozen_string_literal: true

module Hyrax
  # This decorator is used to override logic found in Hyrax v3.4.1
  #
  # Because Hyku has converted the Hyrax::Group model from a PORO to a db-backed active record object,
  # we have to query for existing Hyrax groups instead of initializing empty ones.
  module AdminSetCreateServiceDecorator
    def workflow_agents
      [
        # OVERRIDE: replace #new with #find_by(:name)
        Hyrax::Group.find_by(name: admin_group_name)
      ].tap do |agent_list|
        # The default admin set does not have a creating user
        agent_list << creating_user if creating_user
      end
    end

    # Give registered users deposit access to default admin set
    def create_default_access_for(permission_template:, workflow:)
      permission_template.access_grants.create(agent_type: 'group', agent_id: ::Ability.registered_group_name, access: Hyrax::PermissionTemplateAccess::DEPOSIT)
      deposit = Sipity::Role[Hyrax::RoleRegistry::DEPOSITING]
      # OVERRIDE: replace #new with #find_by(:name)
      workflow.update_responsibilities(role: deposit, agents: Hyrax::Group.find_by(name: 'registered'))
    end
  end
end

Hyrax::AdminSetCreateService.prepend(Hyrax::AdminSetCreateServiceDecorator)
