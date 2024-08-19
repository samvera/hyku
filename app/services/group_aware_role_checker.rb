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

  # Check for the presence of the passed role_name in the User's Roles and
  # the User's Hyrax::Group's Roles.
  def group_aware_role?(role_name)
    return false if current_user.new_record?
    return true if current_user.has_role?(role_name, Site.instance)

    current_user.hyrax_groups.each do |group|
      return true if group.site_role?(role_name)
    end

    false
  end
end
