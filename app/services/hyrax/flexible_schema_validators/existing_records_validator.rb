# frozen_string_literal: true

require 'set'

module Hyrax
  module FlexibleSchemaValidators
    # Validates that classes with existing records in the repository are not removed from the profile.
    class ExistingRecordsValidator
      # @param profile [Hash] M3 profile data
      # @param required_classes [Array<String>] Foundational classes that must be present
      # @param errors [Array<String>] Array to append validation errors to
      def initialize(profile, required_classes, errors)
        @profile = profile
        @required_classes = required_classes
        @errors = errors
      end

      # Validates that classes with existing records are not removed from the profile
      def validate!
        profile_classes = @profile.fetch('classes', {}).keys
        classes_to_check = potential_existing_classes - profile_classes
        classes_with_records = []
        checked_models = Set.new

        classes_to_check.each do |class_name|
          model_class = resolve_model_class(class_name)
          next unless model_class

          next if profile_classes.include?(model_class.to_s)

          model_identifier = model_class.to_s
          next if checked_models.include?(model_identifier)

          checked_models.add(model_identifier)
          begin
            count = Hyrax.query_service.count_all_of_model(model: model_class)
            classes_with_records << model_identifier if count.positive?
          rescue StandardError => e
            Rails.logger.error "Error checking records for #{class_name}: #{e.message}"
          end
        end

        return if classes_with_records.empty?

        @errors << "Classes with existing records cannot be removed from the profile: #{classes_with_records.join(', ')}."
      end

      private

      # @return [Array<String>] Class names that could potentially have existing records
      def potential_existing_classes
        classes = @required_classes.dup

        Hyrax.config.registered_curation_concern_types.each do |concern_type|
          classes << "#{concern_type}Resource"
          classes << concern_type
        end

        classes.uniq
      end

      # @param class_name [String] Class name in profile format
      # @return [Class, nil] Resolved model class or nil if not found
      def resolve_model_class(class_name)
        return Hyrax.config.file_set_model.constantize if class_name == 'Hyrax::FileSet'
        return Hyrax.config.admin_set_model.constantize if class_name == Hyrax.config.admin_set_model
        return Hyrax.config.collection_model.constantize if class_name == Hyrax.config.collection_model

        begin
          class_name.constantize
        rescue NameError
          base_name = class_name.gsub(/Resource$/, '')
          begin
            base_name.constantize
          rescue NameError
            Rails.logger.warn "Could not resolve model class for: #{class_name}"
            nil
          end
        end
      end
    end
  end
end
