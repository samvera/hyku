# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.2 Expand functionality for Groups with Roles Feature
# @see https://github.com/samvera/hyku/wiki/Groups-with-Roles-Feature
module Hyrax
  class Group < ApplicationRecord
    resourcify # Declares Hyrax::Group a resource model so rolify can manage membership

    MEMBERSHIP_ROLE = :member
    DEFAULT_MEMBER_CLASS = ::User
    DEFAULT_NAME_PREFIX = 'group/'

    validates :name, presence: true, uniqueness: true
    has_many :group_roles, dependent: :destroy
    has_many :roles, through: :group_roles
    before_destroy :can_destroy?
    after_destroy :remove_all_members

    def self.name_prefix
      DEFAULT_NAME_PREFIX
    end

    ##
    # @return [Hyrax::Group]
    def self.from_agent_key(key)
      new(key.delete_prefix(name_prefix))
    end

    def self.search(query)
      if query.present?
        left_outer_joins(:roles).where(
          "LOWER(hyrax_groups.humanized_name) LIKE LOWER(:q) " \
          "OR LOWER(hyrax_groups.description) LIKE LOWER(:q) " \
          "OR LOWER(REPLACE(roles.name, '_', ' ')) LIKE LOWER(:q)",
          q: "%#{query}%"
        ).distinct
      else
        includes(:roles).order('roles.sort_value')
      end
    end

    def search_members(query, member_class: DEFAULT_MEMBER_CLASS)
      if query.present? && member_class == DEFAULT_MEMBER_CLASS
        members.where("email LIKE :q OR display_name LIKE :q", q: "%#{query}%")
      else
        members(member_class:)
      end
    end

    # @example group.add_members_by_id(user.id)
    def add_members_by_id(ids, member_class: DEFAULT_MEMBER_CLASS)
      new_members = member_class.unscoped.find(ids)
      Array.wrap(new_members).collect { |m| m.add_role(MEMBERSHIP_ROLE, self) }
    end

    def remove_members_by_id(ids, member_class: DEFAULT_MEMBER_CLASS)
      old_members = member_class.find(ids)
      Array.wrap(old_members).collect { |m| m.remove_role(MEMBERSHIP_ROLE, self) }
    end

    def members(member_class: DEFAULT_MEMBER_CLASS)
      member_class.with_role(MEMBERSHIP_ROLE, self)
    end

    def number_of_users
      members.count
    end

    ##
    # @return [String] a local identifier for this group; for use (e.g.) in ACL
    #   data
    def agent_key
      self.class.name_prefix + name
    end

    def to_sipity_agent
      sipity_agent || create_sipity_agent!
    end

    def default_group?
      return true if RolesService::DEFAULT_HYRAX_GROUPS_WITH_ATTRIBUTES.stringify_keys.keys.include?(name)

      false
    end

    def description_label
      label = description || I18n.t("hyku.admin.groups.description.#{name}")
      return '' if /^translation missing:/.match?(label)

      label
    end

    def has_site_role?(role_name) # rubocop:disable Naming/PredicateName
      site_roles = roles.select { |role| role.resource_type == 'Site' }

      site_roles.map(&:name).include?(role_name.to_s)
    end

    private

    def can_destroy?
      return false if default_group?

      true
    end

    def remove_all_members
      members.map { |m| m.remove_role(MEMBERSHIP_ROLE, self) }
    end

    def sipity_agent
      Sipity::Agent.find_by(proxy_for_id: name, proxy_for_type: self.class.name)
    end

    def create_sipity_agent!
      Sipity::Agent.create!(proxy_for_id: name, proxy_for_type: self.class.name)
    end
  end
end
