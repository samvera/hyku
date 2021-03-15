# frozen_string_literal: true

class Ability
  include Hydra::Ability
  include Hyrax::Ability

  # TODO: :everyone_can_create_curation_concerns allows everyone to create Collections,
  # FileSets, and Works. Because we are developing roles to explicitly grant creation
  # permissions specifically, this will need to be removed from the ability logic after
  # Work roles have been completed (as to not disrupt current use).
  # Once removed, update the following specs:
  # - spec/abilities/collection_ability_spec.rb (collection reader context)
  # - spec/features/collection_reader_role_spec.rb (specs testing creation)
  self.ability_logic += %i[
    everyone_can_create_curation_concerns
    group_permissions
    superadmin_permissions
    collection_roles
  ]

  # Override method from blacklight-access_controls-0.6.2 to define registered to include
  # having a role on this tenant and so that it includes Hyrax::Groups.
  #
  # NOTE: DO NOT RENAME THIS METHOD - it is required for permissions to function properly.
  #
  # All Users are part of the 'public' user_group, and all Users who can authenticate into a tenant are
  # part of the 'registered' group. See User#add_default_group_memberships!
  #
  # This method is not referring to the Hyrax::Groups the Ability's User is a member of; instead,
  # these are more like ability groups; groups that define a set of permissions.
  def user_groups
    return @user_groups if @user_groups

    @user_groups = default_user_groups
    @user_groups |= current_user.hyrax_group_names if current_user.respond_to? :hyrax_group_names
    @user_groups |= ['registered'] if !current_user.new_record? && current_user.roles.count.positive?
    @user_groups
  end

  def group_aware_role_checker
    @group_aware_role_checker ||= GroupAwareRoleChecker.new(user: current_user)
  end

  # Define any customized permissions here.
  def custom_permissions
    can [:create], Account
  end

  def admin_permissions
    return unless admin?
    return if superadmin?

    super
    can [:manage], [Site, Role, User]

    can [:read, :update], Account do |account|
      account == Site.account
    end
  end

  def group_permissions
    return unless admin?

    can :manage, Hyrax::Group
  end

  def superadmin_permissions
    return unless superadmin?

    can :manage, :all
  end

  # TODO: move method to GroupAwareRoleChecker, or use the GroupAwareRoleChecker
  def superadmin?
    current_user.has_role? :superadmin
  end

  # TODO: move method to GroupAwareRoleChecker, or use the GroupAwareRoleChecker
  def admin?
    current_user.has_role?(:admin, Site.instance) || user_groups.include?(admin_group_name)
  end
end
