# frozen_string_literal: true

class GroupRole < ApplicationRecord
  belongs_to :role, class_name: 'Role'
  belongs_to :group, class_name: 'Hyrax::Group'
end
