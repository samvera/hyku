# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.2 Filter certain Roles out of displayed access grants
require_dependency Hyrax::Engine.root.join('app', 'forms', 'hyrax', 'forms', 'collection_form').to_s

Hyrax::Forms::CollectionForm.class_eval do
  # OVERRIDE: Add new method to filter out access_grants for Collection Roles and Work Roles
  # for Collections and AdminSets, respectively. We do this because access_grants for
  # Roles should never be allowed to be removed.
  def filter_access_grants_by_access(access)
    roles_to_filter = ::RolesService::COLLECTION_ROLES + ::RolesService::WORK_ROLES
    filtered_access_grants = permission_template.access_grants.select(&access)
    filtered_access_grants.reject! { |ag| roles_to_filter.include?(ag.agent_id) }

    filtered_access_grants || []
  end
end
