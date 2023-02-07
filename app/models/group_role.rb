# frozen_string_literal: true

class GroupRole < ApplicationRecord
  belongs_to :role, class_name: 'Role', inverse_of: :group_roles
  belongs_to :group, class_name: 'Hyrax::Group', inverse_of: :group_roles
end
