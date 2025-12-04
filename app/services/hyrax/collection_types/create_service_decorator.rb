# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0
# - Give the :collection_manager role MANAGE_ACCESS to all non-AdminSet CollectionTypes by default
# - Give the :collection_editor role CREATE_ACCESS to all non-AdminSet CollectionTypes by default
# - Exclude CREATE_ACCESS from ::Ability.registered_group_name (all registered users) if we are restricting permissions
module Hyrax
  module CollectionTypes
    # @api public
    #
    # Responsible for creating a CollectionType. If no params are given,
    # the default user collection is assumed as defined by:
    #
    # * Hyrax::CollectionType::USER_COLLECTION_MACHINE_ID
    # * Hyrax::CollectionType::USER_COLLECTION_DEFAULT_TITLE
    # * DEFAULT_OPTIONS
    #
    # @see Hyrax:CollectionType
    #
    module CreateServiceDecorator # rubocop:disable Metrics/ModuleLength
      DEFAULT_OPTIONS = {
        description: '',
        nestable: true,
        brandable: true,
        discoverable: true,
        sharable: true,
        share_applies_to_new_works: true,
        allow_multiple_membership: true,
        require_membership: false,
        assigns_workflow: false,
        assigns_visibility: false,
        badge_color: "#663333",
        participants: [
          {
            agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
            agent_id: ::Ability.admin_group_name,
            access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS
          },
          # OVERRIDE: add :collection_manager role to participants array with MANAGE_ACCESS
          {
            agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
            agent_id: 'collection_manager',
            access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS
          },
          # OVERRIDE: add :collection_editor role to participants array with CREATE_ACCESS
          {
            agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
            agent_id: 'collection_editor',
            access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS
          }
        ].tap do |participants|
          # OVERRIDE: exclude group with CREATE_ACCESS for ::Ability.registered_group_name
          # (all registered users) if we are restricting permissions
          unless ActiveModel::Type::Boolean.new.cast(
            ENV.fetch('HYKU_RESTRICT_CREATE_AND_DESTROY_PERMISSIONS', nil)
          )
            participants << {
              agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
              agent_id: ::Ability.registered_group_name,
              access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS
            }
          end
        end
      }.freeze

      USER_COLLECTION_OPTIONS = {
        description: I18n.t('hyrax.collection_types.create_service.default_description'),
        nestable: true,
        brandable: true,
        discoverable: true,
        sharable: true,
        share_applies_to_new_works: false,
        allow_multiple_membership: true,
        require_membership: false,
        assigns_workflow: false,
        assigns_visibility: false,
        badge_color: "#705070",
        participants: [
          {
            agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
            agent_id: ::Ability.admin_group_name,
            access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS
          },
          # OVERRIDE: add :collection_manager role to participants array with MANAGE_ACCESS
          {
            agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
            agent_id: 'collection_manager',
            access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS
          },
          # OVERRIDE: add :collection_editor role to participants array with CREATE_ACCESS
          {
            agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
            agent_id: 'collection_editor',
            access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS
          }
        ].tap do |participants|
          # OVERRIDE: exclude group with CREATE_ACCESS for ::Ability.registered_group_name
          # (all registered users) if we are restricting permissions
          unless ActiveModel::Type::Boolean.new.cast(
            ENV.fetch('HYKU_RESTRICT_CREATE_AND_DESTROY_PERMISSIONS', nil)
          )
            participants << {
              agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
              agent_id: ::Ability.registered_group_name,
              access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS
            }
          end
        end
      }.freeze

      # @api public
      #
      # Add the default participants to a collection_type.
      #
      # @param collection_type_id [Integer] the id of the collection type
      # @note Several checks get the user's groups from the user's ability.
      #   The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.
      #   If you try to get the ability from the user, you end up in an infinite loop.
      # rubocop:disable Metrics/MethodLength
      def add_default_participants(collection_type_id)
        return unless collection_type_id
        default_participants = [{ agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                                  agent_id: ::Ability.admin_group_name,
                                  access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS },
                                # OVERRIDE: add :collection_manager role to participants array with MANAGE_ACCESS
                                { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                                  agent_id: 'collection_manager',
                                  access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS },
                                # OVERRIDE: add :collection_editor role to participants array with CREATE_ACCESS
                                { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                                  agent_id: 'collection_editor',
                                  access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS }].tap do |participants|
                                    # OVERRIDE: exclude group with CREATE_ACCESS for ::Ability.registered_group_name
                                    # (all registered users) if we are restricting permissions
                                    unless ActiveModel::Type::Boolean.new.cast(
                                      ENV.fetch('HYKU_RESTRICT_CREATE_AND_DESTROY_PERMISSIONS', nil)
                                    )
                                      participants << { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                                                        agent_id: ::Ability.registered_group_name,
                                                        access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS }
                                    end
                                  end
        add_participants(collection_type_id, default_participants)
      end
    end # rubocop:enable Metrics/ModuleLength
  end
end

Hyrax::CollectionTypes::CreateService.singleton_class.send(:prepend, Hyrax::CollectionTypes::CreateServiceDecorator)
Hyrax::CollectionTypes::CreateService::DEFAULT_OPTIONS = Hyrax::CollectionTypes::CreateServiceDecorator::DEFAULT_OPTIONS
Hyrax::CollectionTypes::CreateService::USER_COLLECTION_OPTIONS = Hyrax::CollectionTypes::CreateServiceDecorator::USER_COLLECTION_OPTIONS
