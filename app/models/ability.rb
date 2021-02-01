# frozen_string_literal: true

class Ability
  include Hydra::Ability
  include Hyrax::Ability

  self.ability_logic += %i[
    everyone_can_create_curation_concerns
    group_permissions
    superadmin_permissions
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
    @user_groups |= current_user.groups if current_user.respond_to? :groups
    @user_groups |= ['registered'] if !current_user.new_record? && current_user.roles.count.positive?
    @user_groups
  end

  # NOTE: This is an alias for #user_groups to clarify what the method is used for.
  # This is necessary because #user_groups overrides a method from a gem. See
  # Ability#user_groups for more information.
  def permission_set
    user_groups
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

  # Override method from Hyrax v2.5.1
  def editor_abilities
    can :read, ContentBlock
    can :read, :admin_dashboard if admin?
    can :update, ContentBlock if admin?
    can :edit, ::SolrDocument do |solr_doc|
      return true if admin?

      solr_doc.collection? && collection_manager? || collection_editor?
    end
  end

  def superadmin_permissions
    return unless superadmin?

    can :manage, :all
  end

  def superadmin?
    current_user.has_role? :superadmin
  end

  # NOTE: Override method from Hyrax 2.9.0 to take roles
  # on the User into account instead of only looking at #permission_set.
  def admin?
    current_user.has_role?(:admin, Site.instance) || permission_set.include?(admin_group_name)
  end

  def collection_manager?
    current_user.has_role?(:collection_manager, Site.instance)
  end

  def collection_editor?
    current_user.has_role?(:collection_editor, Site.instance)
  end

  def collection_reader?
    current_user.has_role?(:collection_reader, Site.instance)
  end
end
