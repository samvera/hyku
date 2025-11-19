# frozen_string_literal: true

class Ability
  include Hydra::Ability
  include Hyrax::Ability
  include GroupAwareRoleChecker
  # Add custom ability roles
  include Hyrax::Ability::UserAbility
  include Hyrax::Ability::WorkAbility

  self.ability_logic += %i[
    group_permissions
    superadmin_permissions
    collection_roles
    user_roles
    work_roles
    featured_collection_abilities
  ]
  # If the Groups with Roles feature is disabled, allow registered users to create curation concerns
  # (Works, Collections, and FileSets). Otherwise, omit this ability logic as to not
  # conflict with the roles that explicitly grant creation permissions.
  unless ActiveModel::Type::Boolean.new.cast(
    ENV.fetch('HYKU_RESTRICT_CREATE_AND_DESTROY_PERMISSIONS', nil)
  )
    self.ability_logic += %i[everyone_can_create_curation_concerns]
  end

  # OVERRIDE METHOD from blacklight-access_controls v6.0.1
  #
  # NOTE: DO NOT RENAME THIS METHOD - it is required for permissions to function properly.
  #
  # This method is used when checking if the current user has access to a given SolrDocument.
  # For example, if #user_groups includes an element called "test", and a document's read access groups
  # include an element called "test", then the user has read access to the document.
  # This method is NOT referring to the Hyrax::Groups that the User is a member of. For that, see User#hyrax_groups.
  def user_groups
    return @user_groups if @user_groups

    @user_groups = default_user_groups
    # TODO: necessary to include #hyrax_group_names?
    @user_groups |= current_user.hyrax_group_names if current_user.respond_to? :hyrax_group_names
    @user_groups |= ['registered'] if !current_user.new_record? && current_user.roles.count.positive?
    # OVERRIDE: add the names of all user's roles to the array of user_groups
    @user_groups |= all_user_and_group_roles

    @user_groups
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
    can [:update], RolesService

    can [:read, :update], Account do |account|
      account == Site.account
    end

    # OVERRIDE: only admin users can make other users admins
    can :grant_admin_role, User

    # OVERRIDE: add custom action used in WorkAbility for "Delete Selected" button on Works dashboard index views
    can :batch_delete, :works
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

  # @return [Array<String>] a list of all role names that apply to the user
  def all_user_and_group_roles
    return @all_user_and_group_roles if @all_user_and_group_roles

    @all_user_and_group_roles = []
    RolesService::DEFAULT_ROLES.each do |role_name|
      @all_user_and_group_roles |= [role_name.to_s] if public_send("#{role_name}?")
    end

    @all_user_and_group_roles
  end

  def featured_collection_abilities
    can %i[create destroy update], FeaturedCollection if admin?
  end

  def can_import_works?
    can_create_any_work?
  end

  def can_export_works?
    can_create_any_work?
  end

  ##
  # @api public
  #
  # Overrides hydra-head, (and restores the method from blacklight-access-controls)
  def download_permissions
    can :download, [::String, ::Valkyrie::ID] do |id|
      test_download(id.to_s)
    end

    can :download, ::SolrDocument do |obj|
      if obj.pdf? && !obj.show_pdf_download_button
        false
      else
        cache.put(obj.id, obj)
        test_download(obj.id)
      end
    end
  end

  def test_download(*args)
    account = Site.account

    # In cases where we don't have an account.
    return super unless account

    if account.settings[:allow_downloads].nil? || account.settings[:allow_downloads].to_i.nonzero?
      super
    else
      false
    end
  end
end
