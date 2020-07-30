# frozen_string_literal: true

module Hyku
  class Group < ApplicationRecord
    self.table_name = 'hyku_groups'

    resourcify # Declares Hyku::Group a resource model so rolify can manage membership

    MEMBERSHIP_ROLE = :member
    DEFAULT_MEMBER_CLASS = User

    validates :name, presence: true

    def self.search(query)
      if query.present?
        where("name LIKE :q OR description LIKE :q", q: "%#{query}%")
      else
        all
      end
    end

    def search_members(query, member_class: DEFAULT_MEMBER_CLASS)
      if query.present? && member_class == DEFAULT_MEMBER_CLASS
        members.where("email LIKE :q OR display_name LIKE :q", q: "%#{query}%")
      else
        members(member_class: member_class)
      end
    end

    def add_members_by_id(ids, member_class: DEFAULT_MEMBER_CLASS)
      new_members = member_class.find(ids)
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
  end
end
