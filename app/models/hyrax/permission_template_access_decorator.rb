# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 #titleize agent_id for groups since we are displaying their humanized names in the dropdown
module Hyrax
  module PermissionTemplateAccessDecorator
    def label
      return agent_id unless agent_type == Hyrax::PermissionTemplateAccess::GROUP

      case agent_id
      when ::Ability.registered_group_name # OVERRIDE: use dynamic method instead of hard-coded value ("registered")
        I18n.t('hyrax.admin.admin_sets.form_participant_table.registered_users')
      when ::Ability.admin_group_name
        I18n.t('hyrax.admin.admin_sets.form_participant_table.admin_users')
      else
        agent_id.titleize # OVERRIDE: add #titleize
      end
    end
  end
end

Hyrax::PermissionTemplateAccess.prepend(Hyrax::PermissionTemplateAccessDecorator)
