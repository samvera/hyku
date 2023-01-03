# frozen_string_literal: true

# OVERRIDE FILE from Hryax v2.9.0
require_dependency Hyrax::Engine.root.join('app', 'models', 'hyrax', 'collection_type_participant').to_s

Hyrax::CollectionTypeParticipant.class_eval do
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

  # OVERRIDE: Add new method to determine if a participant is referring
  # to the admin group.
  def admin_group?
    agent_type == Hyrax::CollectionTypeParticipant::GROUP_TYPE && agent_id == ::Ability.admin_group_name
  end
end
