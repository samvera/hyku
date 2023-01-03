# frozen_string_literal: true

# OVERRIDE FILE from Hryax v2.9.0
require_dependency Hyrax::Engine.root.join('app', 'forms', 'hyrax', 'forms', 'admin', 'collection_type_form').to_s

Hyrax::Forms::Admin::CollectionTypeForm.class_eval do
  # OVERRIDE: Add new method to filter out collection_type_participants for Collection Roles in the UI. We
  # do this because collection_type_participants for Collection Roles should never be allowed to be removed.
  def filter_participants_by_access(access)
    filtered_participants = collection_type_participants.select(&access)
    filtered_participants.reject! { |ag| ::RolesService::COLLECTION_ROLES.include?(ag.agent_id) }

    filtered_participants || []
  end
end
