# frozen_string_literal: true

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
