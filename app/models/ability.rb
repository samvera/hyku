class Ability
  include Hydra::Ability

  include CurationConcerns::Ability
  include Sufia::Ability

  self.ability_logic += [:everyone_can_create_curation_concerns]

  def custom_permissions
    can [:create], Account
  end

  def admin_permissions
    super

    can [:manage], [Site, Role]

    restrict_site_admin_permissions
  end

  def restrict_site_admin_permissions
    # override curation_concerns admin roles to disable admin privileges on global models
    cannot [:manage, :create, :discover, :show, :read, :edit, :update, :destroy], global_models

    can [:read, :create, :show, :edit, :update], Account do |account|
      Site.account == account
    end
  end

  private

    def global_models
      [Account]
    end

    # Override admin? helper to use rolify roles
    def admin?
      current_user.has_role?(:admin)
    end
end
