# frozen_string_literal: true

require 'json_schemer'
require_relative 'core_metadata_validator'

module Hyrax
  class FlexibleSchemaValidatorService
    DEFAULT_SCHEMA = Rails.root.join('lib', 'flexible', 'm3_json_schema.json')
    REQUIRED_CLASSES = [
      Hyrax.config.admin_set_model,
      Hyrax.config.collection_model,
      Hyrax.config.file_set_model
    ].map { |str| str.gsub(/^::/, '') }

    attr_reader :profile, :schema, :schemer, :errors

    # Initializes a new FlexibleSchemaValidatorService.
    #
    # @param profile [Hash] the flexible metadata profile to validate
    # @param schema [Pathname, String] the JSON schema to validate against.
    #   Defaults to {DEFAULT_SCHEMA}.
    # @return [void]
    def initialize(profile:, schema: default_schema)
      @profile = profile
      @schema = schema
      @schemer = JSONSchemer.schema(schema)
      @errors = []
    end

    # Execute all validation routines and populate {#errors} with any
    # issues discovered.
    #
    # @return [void]
    def validate!
      validate_required_classes
      validate_class_availability
      validate_available_on_classes_defined
      validate_schema
      validate_label_prop
      validate_enabled_work_types
      CoreMetadataValidator.new(profile: profile, errors: @errors).validate!
    end

    # The default JSON schema used when no custom schema is provided.
    #
    # @return [Pathname]
    def default_schema
      DEFAULT_SCHEMA
    end

    # Classes that MUST be present in every flexible metadata profile.
    #
    # @return [Array<String>]
    def required_classes
      REQUIRED_CLASSES
    end

    private

    # Validates that the profile's work types correspond to the site's
    # enabled work types, adding human-readable error messages for any
    # discrepancies.
    #
    # @return [void]
    def validate_enabled_work_types
      enabled_work_types = Site.instance.available_works
      all_work_types = Hyrax.config.registered_curation_concern_types
      profile_work_types = profile['classes'].keys.map { |klass| klass.gsub(/Resource$/, '') } & all_work_types

      missing_from_profile = enabled_work_types - profile_work_types
      @errors << "Enabled work types not in profile: #{missing_from_profile.join(', ')}." if missing_from_profile.any?

      not_enabled_in_site = profile_work_types - enabled_work_types
      return if not_enabled_in_site.empty?

      @errors << "Profile includes work types that are not enabled: #{not_enabled_in_site.join(', ')}."
    end

    # Runs JSON schema validation and translates resulting errors into
    # user-friendly messages appended to {#errors}.
    #
    # @return [void]
    def validate_schema
      schemer.validate(profile).to_a&.each do |error|
        pointer = error['data_pointer']
        type = error['type']

        if pointer.end_with?('/available_on') && error['data'].nil? && type == 'object'
          @errors << "Schema error at `#{pointer}`: `available_on` cannot be empty and must have a `class` or `context` sub-property."
        elsif type == 'required'
          missing_keys = error.dig('details', 'missing_keys')&.join("', '")
          @errors << "Schema error at `#{pointer}`: Missing required properties: '#{missing_keys}'."
        else
          @errors << "Schema error at `#{pointer}`: Invalid value `#{error['data'].inspect}` for type `#{type}`."
        end
      end
    end

    # Ensures that all required classes are defined in the profile.
    #
    # @return [void]
    def validate_required_classes
      missing_classes = required_classes - profile['classes'].keys
      return if missing_classes.empty?

      @errors << "Missing required classes: #{missing_classes.join(', ')}."
    end

    # Checks that any class referenced in the profile is a registered
    # Hyrax curation concern type.
    #
    # @return [void]
    def validate_class_availability
      profile_classes = profile['classes'].keys
      properties = profile['properties']
      available_on_classes = properties.keys.flat_map do |key|
        properties[key].fetch('available_on', nil)&.fetch('class', nil)
      end.compact.uniq

      combined_classes = profile_classes + available_on_classes
      unique_classes = combined_classes.uniq
      filtered_classes = unique_classes - required_classes
      classes = filtered_classes.map { |klass| klass.gsub(/(?<=.)Resource$/, '') }

      invalid_classes = classes.filter_map do |klass|
        klass unless Hyrax.config.registered_curation_concern_types.include?(klass)
      end

      return if invalid_classes.empty?

      @errors << "Invalid classes: #{invalid_classes.join(', ')}."
    end

    # Validates that every class referenced under `available_on.class` is also
    # defined in the profile's top-level `classes` section.
    #
    # This guards against a common mistake where a class is removed from the
    # `classes` section but lingering references remain in one or more
    # properties, which would otherwise lead to runtime errors.
    # @return [void]
    def validate_available_on_classes_defined
      properties = profile['properties'] || {}

      referenced_classes = properties.values.flat_map do |prop|
        prop.dig('available_on', 'class')
      end.compact.uniq

      undefined_classes = referenced_classes - profile['classes'].keys

      return if undefined_classes.empty?

      @errors << "Classes referenced in `available_on` but not defined in `classes`: #{undefined_classes.join(', ')}."
    end

    # Validates that a `label` property exists and that it is available on
    # `Hyrax::FileSet`.
    #
    # @return [void]
    def validate_label_prop
      label_prop = profile.dig('properties', 'label')
      unless label_prop
        @errors << "A `label` property is required."
        return
      end

      available_on_classes = label_prop.dig('available_on', 'class')
      return if available_on_classes&.include?('Hyrax::FileSet')

      @errors << "Label must be available on Hyrax::FileSet."
    end
  end
end
