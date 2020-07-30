# frozen_string_literal: true

class Ability
  include Hydra::Ability
  include Hyrax::Ability

  self.ability_logic += %i[
    everyone_can_create_curation_concerns
    group_permissions
    superadmin_permissions
  ]

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

    can :manage, Hyku::Group
  end

  def superadmin_permissions
    return unless superadmin?

    can :manage, :all
  end

  def superadmin?
    current_user.has_role? :superadmin
  end
end
