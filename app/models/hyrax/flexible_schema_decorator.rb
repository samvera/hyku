# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.5 to add a validator for the m3 profile upload which will
#   reject profiles that have errors which would not break the application
#   by letting a bad profile through

module Hyrax
  module FlexibleSchemaDecorator
    private

    def validate_profile_classes
      validation_service = Hyrax::FlexibleSchemaValidatorService.new(profile:)
      validation_service.validate!

      validation_service.errors.each do |e|
        errors.add(:profile, e.to_s)
      end
    end
  end
end

Hyrax::FlexibleSchema.prepend(Hyrax::FlexibleSchemaDecorator)
