# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0rc2 Expand functionality for Groups with Roles Feature
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

    ##
    # What is going on here?  In Hyrax proper, the Group model is a plain old Ruby object (PORO). In
    # Hyku, the {Hyrax::Group} is based on ActiveRecord.
    #
    # The Hyrax version instantiates with a single string parameter.  Importantly, we want to re-use
    # the Hyrax::Workflow::PermissionQuery logic, without re-writing it.  In particular we want to
    # consider the Hyrax::Workflow::PermissionQuery#scope_processing_agents_for which casts the
    # group to a Sipity::Agent
    #
    # @see https://github.com/samvera/hyrax/blob/main/app/models/hyrax/group.rb
    # @see https://github.com/samvera/hyrax/blob/main/app/services/hyrax/workflow/permission_query.rb
    def self.new(*args)
      # This logic path is likely coming from Hyrax specific code; in which it expects a string.
      if args.size == 1 && args.first.is_a?(String)
        find_by(name: args.first) || super(name: args.first)
      else
        super
      end
    end

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
      # NOTE: Depending on configuration of I18n, we might have a translation missing or a false
      # value; we're noticing `false` cases with upgrades of Rails.
      return '' if label == false
      return '' if /^translation missing:/.match?(label)

      label
    end

    def site_role?(role_name)
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
