# frozen_string_literal: true

module Sample
  class PermissionTemplateService
    def self.create_for_collection(collection, user)
      return if Hyrax::PermissionTemplate.find_by(source_id: collection.id)

      permission_template = Hyrax::PermissionTemplate.create!(source_id: collection.id)

      # Add manage access for the user
      permission_template.access_grants.create!(
        agent_type: Hyrax::PermissionTemplateAccess::USER,
        agent_id: user.user_key,
        access: Hyrax::PermissionTemplateAccess::MANAGE
      )

      # Add manage access for collection_manager group
      permission_template.access_grants.create!(
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: 'collection_manager',
        access: Hyrax::PermissionTemplateAccess::MANAGE
      )

      # Add view access for collection_editor group
      permission_template.access_grants.create!(
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: 'collection_editor',
        access: Hyrax::PermissionTemplateAccess::VIEW
      )

      # Add view access for collection_reader group
      permission_template.access_grants.create!(
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: 'collection_reader',
        access: Hyrax::PermissionTemplateAccess::VIEW
      )

      collection.permission_template.reset_access_controls_for(collection: collection, interpret_visibility: true)
    end

    def self.create_for_valkyrie_collection(collection, user)
      return if Hyrax::PermissionTemplate.find_by(source_id: collection.id.to_s)

      permission_template = Hyrax::PermissionTemplate.create!(source_id: collection.id.to_s)

      # Add manage access for the user
      permission_template.access_grants.create!(
        agent_type: Hyrax::PermissionTemplateAccess::USER,
        agent_id: user.user_key,
        access: Hyrax::PermissionTemplateAccess::MANAGE
      )

      # Add manage access for collection_manager group
      permission_template.access_grants.create!(
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: 'collection_manager',
        access: Hyrax::PermissionTemplateAccess::MANAGE
      )

      # Add view access for collection_editor group
      permission_template.access_grants.create!(
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: 'collection_editor',
        access: Hyrax::PermissionTemplateAccess::VIEW
      )

      # Add view access for collection_reader group
      permission_template.access_grants.create!(
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: 'collection_reader',
        access: Hyrax::PermissionTemplateAccess::VIEW
      )

      # For Valkyrie resources, we may need to manually apply permissions
      # This depends on how permissions are handled in the Valkyrie implementation
    end
  end
end
