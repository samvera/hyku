# frozen_string_literal: true

class Role < ApplicationRecord
  has_and_belongs_to_many :users, join_table: :users_roles
  has_many :group_roles
  has_many :groups, through: :group_roles

  belongs_to :resource,
             polymorphic: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  scopify

  scope :site, -> { where(resource_type: "Site") }
end
