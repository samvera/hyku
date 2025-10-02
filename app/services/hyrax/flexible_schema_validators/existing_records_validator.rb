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

      # Validates that no classes with existing records in the repository have been
      # removed from the profile.
      #
      # @return [void]
      def validate!
        profile_classes_set = Set.new(@profile.fetch('classes', {}).keys)
        classes_to_check = potential_existing_classes - profile_classes_set.to_a
        classes_with_records = []
        checked_models = Set.new

        classes_to_check.each do |class_name|
          check_class_for_existing_records(class_name, checked_models, profile_classes_set, classes_with_records)
        end

        return if classes_with_records.empty?

        @errors << "Classes with existing records cannot be removed from the profile: #{classes_with_records.uniq.join(', ')}."
      end

      private

      # Helper method to check a single class for existing records and validate its presence in the profile.
      #
      # @param class_name [String] The name of the class to check.
      # @param checked_models [Set] A set of model names that have already been processed to avoid duplicates.
      # @param profile_classes_set [Set] A set of class names defined in the new profile.
      # @param classes_with_records [Array] An array to accumulate classes that have records but are missing from the profile.
      # @return [void]
      def check_class_for_existing_records(class_name, checked_models, profile_classes_set, classes_with_records)
        model_class = resolve_model_class(class_name)
        return unless model_class

        model_identifier = model_class.to_s
        counterpart_identifier = counterpart_for(model_identifier)

        return if already_checked?(model_identifier, counterpart_identifier, checked_models)
        mark_as_checked(model_identifier, counterpart_identifier, checked_models)

        return unless model_has_records?(model_class, class_name)

        is_present = profile_classes_set.include?(model_identifier) || profile_classes_set.include?(counterpart_identifier)
        classes_with_records << model_identifier unless is_present
      end

      # Determines the counterpart model name (e.g., Image -> ImageResource).
      def counterpart_for(model_identifier)
        if model_identifier.end_with?('Resource')
          model_identifier.chomp('Resource')
        else
          "#{model_identifier}Resource"
        end
      end

      # Checks if a model or its counterpart has already been processed.
      def already_checked?(model_id, counterpart_id, checked_models)
        checked_models.include?(model_id) || checked_models.include?(counterpart_id)
      end

      # Marks both a model and its counterpart as processed.
      def mark_as_checked(model_id, counterpart_id, checked_models)
        checked_models.add(model_id)
        checked_models.add(counterpart_id)
      end

      # Queries the repository to see if a given model has any records.
      def model_has_records?(model_class, class_name)
        Hyrax.query_service.count_all_of_model(model: model_class).positive?
      rescue StandardError => e
        Rails.logger.error "Error checking records for #{class_name}: #{e.message}"
        false
      end

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
        rescue NameError, LoadError
          base_name = class_name.gsub(/Resource$/, '')
          begin
            base_name.constantize
          rescue NameError, LoadError
            Rails.logger.warn "Could not resolve model class for: #{class_name}"
            nil
          end
        end
      end
    end
  end
end
