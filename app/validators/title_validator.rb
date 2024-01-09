# frozen_string_literal: true
class TitleValidator < ActiveModel::Validator
  # ensure the property exists and is in the controlled vocabulary
  def validate(record)
    record.title.present?

    record.errors.add :title, 'Your work must have a title.'
  end
end
