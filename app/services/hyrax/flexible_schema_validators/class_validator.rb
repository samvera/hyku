# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    # Handles class-related validations for flexible metadata profiles
    class ClassValidator
      def initialize(profile, required_classes, errors)
        @profile = profile
        @required_classes = required_classes
        @errors = errors
      end

      # Checks that any class referenced in the profile is a registered
      # Hyrax curation concern type.
      def validate_availability!
        profile_classes = @profile['classes'].keys
        properties = @profile['properties']
        available_on_classes = properties.keys.flat_map do |key|
          properties[key].fetch('available_on', nil)&.fetch('class', nil)
        end.compact.uniq

        combined_classes = profile_classes + available_on_classes
        unique_classes = combined_classes.uniq
        filtered_classes = unique_classes - @required_classes
        classes = filtered_classes.map { |klass| klass.gsub(/(?<=.)Resource$/, '') }

        invalid_classes = classes.filter_map do |klass|
          klass unless Hyrax.config.registered_curation_concern_types.include?(klass)
        end

        return if invalid_classes.empty?

        @errors << "Invalid classes: #{invalid_classes.join(', ')}."
      end

      # Validates that every class referenced under `available_on.class` is also
      # defined in the profile's top-level `classes` section.
      def validate_references!
        properties = @profile['properties'] || {}

        referenced_classes = properties.values.flat_map do |prop|
          prop.dig('available_on', 'class')
        end.compact.uniq

        undefined_classes = referenced_classes - @profile['classes'].keys

        return if undefined_classes.empty?

        @errors << "Classes referenced in `available_on` but not defined in `classes`: #{undefined_classes.join(', ')}."
      end

      # Validates that classes with existing records in the repository are not removed from the profile.
      def validate_existing_records!
        classes_to_check = potential_existing_classes - @profile['classes'].keys
        classes_with_records = []
        checked_models = Set.new

        classes_to_check.each do |class_name|
          model_class = resolve_model_class(class_name)
          next unless model_class

          model_identifier = model_class.to_s
          next if checked_models.include?(model_identifier)

          begin
            count = Hyrax.query_service.count_all_of_model(model: model_class)
            if count.positive?
              classes_with_records << model_identifier
              checked_models.add(model_identifier)
            end
          rescue StandardError => e
            Rails.logger.error "Error checking records for #{class_name}: #{e.message}"
          end
        end

        return if classes_with_records.empty?

        @errors << "Classes with existing records cannot be removed from the profile: #{classes_with_records.join(', ')}."
      end

      private

      # Returns classes that could potentially have existing records
      # @return [Array<String>] Class names in profile format
      def potential_existing_classes
        classes = @required_classes.dup

        Hyrax.config.registered_curation_concern_types.each do |concern_type|
          classes << "#{concern_type}Resource"
          classes << concern_type
        end

        classes.uniq
      end

      # Resolves a profile class name to its actual model class
      # @param class_name [String] Class name in profile format (e.g., 'GenericWorkResource')
      # @return [Class, nil] The resolved model class or nil if not found
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
