# frozen_string_literal: true

# Loop group memberships into the role-checking process
module GroupAwareRoleChecker
  # Dynamically define all #<role_name>? methods so that, as more roles are added,
  # their role checker methods are automatically defined
  RolesService::DEFAULT_ROLES.each do |role_name|
    define_method(:"#{role_name}?") do
      group_aware_role?(role_name)
    end
  end

  private

  def current_user_hyrax_groups(site_instance)
    @current_user_hyrax_groups ||= {}
    @current_user_hyrax_groups[site_instance.id] ||= current_user.hyrax_groups
  end

  # Check for the presence of the passed role_name in the User's Roles and
  # the User's Hyrax::Group's Roles.
  def group_aware_role?(role_name)
    return false if current_user.new_record?

    @group_aware_role_cache ||= {}

    site_instance = Site.instance

    cache_key = [role_name, site_instance.id]
    return @group_aware_role_cache[cache_key] if @group_aware_role_cache.key?(cache_key)

    @group_aware_role_cache[cache_key] =
      current_user.has_role?(role_name, site_instance) ||
      current_user_hyrax_groups(site_instance).any? { |group| group.site_role?(role_name) }
  end
end
