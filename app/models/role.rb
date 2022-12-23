# frozen_string_literal: true

class Role < ApplicationRecord
  has_and_belongs_to_many :users, join_table: :users_roles
  has_many :group_roles, dependent: :destroy
  has_many :groups, through: :group_roles

  belongs_to :resource,
             polymorphic: true

  before_create :set_sort_value

  validates :name, presence: true
  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  scopify

  scope :site, -> { where(resource_type: "Site") }

  def description_label
    label = description || I18n.t("hyku.admin.roles.description.#{name}")
    return '' if label =~ /^translation missing:/

    label
  end

  def set_sort_value
    self.sort_value = if name == 'admin'
                        0
                      elsif name =~ /manager/
                        1
                      elsif name =~ /editor/
                        2
                      elsif name =~ /depositor/
                        3
                      elsif name =~ /reader/
                        4
                      else
                        99
                      end
  end

  # By default in Hyrax, permissions can only be assigned to Groups or Users. For the
  # Groups with Roles feature permissions to work, we treat Role the same as a group
  # when assigning permissions to it.
  # This method is needed to find permissions assigned to Roles.
  # @see Hyrax::PermissionManagerDecorator#update_groups_for
  ##
  # @return [String] a local identifier for this group; for use (e.g.) in ACL
  #   data
  def agent_key
    Hyrax::Group.name_prefix + name
  end
end
