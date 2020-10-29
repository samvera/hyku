# frozen_string_literal: true

class Ability
  include Hydra::Ability
  include Hyrax::Ability

  self.ability_logic += %i[
    everyone_can_create_curation_concerns
    group_permissions
    superadmin_permissions
  ]

  ##
  # Override method from blacklight-access_controls v0.6.2 to use Hyrax::Groups.
  # NOTE(bkiahstroud): DO NOT RENAME THIS METHOD - it is required for
  # permissions to function properly.
  def user_groups
    current_user.groups
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
