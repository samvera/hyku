# frozen_string_literal: true

# One auth to rule them all!
# Tie together all the concepts of auth in Hyrax, Hyku, and their dependencies.
class PermissionSetService

  attr_reader :user

  # @param [User] The User for whom the permissions will be evaluated.
  def initialize(user:)
    user_id = user.try(:id) || user

    @user = User.unscoped.find(user_id)
  end

  # Check the User's Roles and the User's Hyrax::Group's Roles
  # for the presence of the :collection_manager Role.
  def collection_manager?
    @user.reload
    return true if @user.has_role?('collection_manager', Site.instance)

    @user.hyrax_groups.each do |group|
      return group.roles.map(&:name).include?('collection_manager')
    end

    false
  end
end
