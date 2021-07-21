# frozen_string_literal: true

class User < ApplicationRecord
  # Includes lib/rolify from the rolify gem
  rolify
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Hyrax behaviors.
  include Hyrax::User
  include Hyrax::UserUsageStats

  attr_accessible :email, :password, :password_confirmation if Blacklight::Utils.needs_attr_accessible?
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :invitable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  after_save :add_default_group_memberships!

  scope :for_repository, ->{
    joins(:roles)
  }

  # set default scope to exclude guest users
  def self.default_scope
    where(guest: false)
  end

  scope :for_repository, -> {
    joins(:roles)
  }

  scope :registered, -> { for_repository.group(:id).where(guest: false) }

  # set default scope to exclude guest users
  def self.default_scope
    where(guest: false)
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier.
  def to_s
    email
  end

  def is_superadmin
    has_role? :superadmin
  end

  # This comes from a checkbox in the proprietor interface
  # Rails checkboxes are often nil or "0" so we handle that
  # case directly
  def is_superadmin=(value)
    value = ActiveModel::Type::Boolean.new.cast(value)
    if value
      add_role :superadmin
    else
      remove_role :superadmin
    end
  end

  def site_roles
    roles.site
  end

  def site_roles=(roles)
    roles.reject!(&:blank?)

    existing_roles = site_roles.pluck(:name)
    new_roles = roles - existing_roles
    removed_roles = existing_roles - roles

    new_roles.each do |r|
      add_role r, Site.instance
    end

    removed_roles.each do |r|
      remove_role r, Site.instance
    end
  end

  # Hyrax::Group memberships are tracked through User#roles. This method looks up
  # the Hyrax::Groups the user is a member of and returns each one in an Array.
  # Example:
  #   u = User.last
  #   u.roles
  #   => #<ActiveRecord::Associations::CollectionProxy [#<Role id: 8, name: "member", resource_type: "Hyrax::Group", resource_id: 2,...>]>
  #   u.hyrax_groups
  #   => [#<Hyrax::Group id: 2, name: "registered", description: nil,...>]
  def hyrax_groups
    roles.where(name: 'member', resource_type: 'Hyrax::Group').map(&:resource).uniq
  end

  # Override method from hydra-access-controls v11.0.0 to use Hyrax::Groups.
  # NOTE: DO NOT RENAME THIS METHOD - it is required for permissions to function properly.
  # @return [Array] Hyrax::Group names the User is a member of
  def groups
    hyrax_groups.map(&:name)
  end

  # NOTE: This is an alias for #groups to clarify what the method is doing.
  # This is necessary because #groups overrides a method from a gem.
  # @return [Array] Hyrax::Group names the User is a member of
  def hyrax_group_names
    groups
  end

  # If this user is the first user on the tenant, they become its admin
  # unless we are in the global tenant
  def add_default_roles
    return if Account.global_tenant?

    add_role :admin, Site.instance unless self.class.joins(:roles).where("roles.name = ?", "admin").any?
    # Role for any given site
    add_role :registered, Site.instance
  end
end
