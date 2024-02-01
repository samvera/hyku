# frozen_string_literal: true
require 'title_validator'

class ImageResourceChangeSet < Hyrax::ChangeSet
  property :title, multiple: true, required: true

  # validating change_sets => https://github.com/samvera/valkyrie/wiki/Validating-change-sets
  validates :title, presence: true
  validates_with TitleValidator
end
