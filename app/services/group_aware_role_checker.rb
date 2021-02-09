# frozen_string_literal: true

# One auth to rule them all!
# Tie together all the concepts of auth in Hyrax, Hyku, and their dependencies.
class GroupAwareRoleChecker

  attr_reader :user

  # @param [User] The User for whom the permissions will be evaluated.
  def initialize(user:)
    user_id = user.try(:id) || user

    @user = User.unscoped.find(user_id)
  end

  def collection_manager?
    has_group_aware_role?('collection_manager')
  end

  def collection_editor?
    has_group_aware_role?('collection_editor')
  end

  def collection_reader?
    has_group_aware_role?('collection_reader')
  end

  private

  # Check for the presence of the passed role_name in the User's Roles and
  # the User's Hyrax::Group's Roles.
  def has_group_aware_role?(role_name)
    @user.reload
    return true if @user.has_role?(role_name, Site.instance)

    @user.hyrax_groups.each do |group|
      return group.roles.map(&:name).include?(role_name)
    end

    false
  end
end
