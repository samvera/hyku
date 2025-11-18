# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 Expand functionality for Groups with Roles feature
module Hyrax
  module CollectionTypeParticipantDecorator
    # OVERRIDE: #titleize agent_id for groups since we are displaying their humanized names in the dropdown
    def label
      return agent_id unless agent_type == Hyrax::CollectionTypeParticipant::GROUP_TYPE

      case agent_id
      when ::Ability.registered_group_name
        I18n.t('hyrax.admin.admin_sets.form_participant_table.registered_users')
      when ::Ability.admin_group_name
        I18n.t('hyrax.admin.admin_sets.form_participant_table.admin_users')
      else
        agent_id.titleize # OVERRIDE: add #titleize
      end
    end

    # Add new method to determine if a participant is referring to the admin group.
    def admin_group?
      agent_type == Hyrax::CollectionTypeParticipant::GROUP_TYPE && agent_id == ::Ability.admin_group_name
    end
  end
end

Hyrax::CollectionTypeParticipant.prepend(Hyrax::CollectionTypeParticipantDecorator)
