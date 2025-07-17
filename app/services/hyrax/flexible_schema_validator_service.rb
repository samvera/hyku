# frozen_string_literal: true

require 'json_schemer'

module Hyrax
  class FlexibleSchemaValidatorService
    DEFAULT_SCHEMA = Rails.root.join('lib', 'flexible', 'm3_json_schema.json')
    REQUIRED_CLASSES = [
      Hyrax.config.admin_set_model,
      Hyrax.config.collection_model,
      Hyrax.config.file_set_model
    ].map { |str| str.gsub(/^::/, '') }

    attr_reader :profile, :schema, :schemer, :errors

    def initialize(profile:, schema: default_schema)
      @profile = profile
      @schema = schema
      @schemer = JSONSchemer.schema(schema)
      @errors = []
    end

    def validate!
      validate_required_classes
      validate_class_availability
      validate_schema
      validate_label_prop
      validate_core_metadata_properties
    end

    def default_schema
      DEFAULT_SCHEMA
    end

    def required_classes
      REQUIRED_CLASSES
    end

    private

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

    def validate_required_classes
      missing_classes = required_classes - profile['classes'].keys
      return if missing_classes.empty?

      @errors << "Missing required classes: #{missing_classes.join(', ')}."
    end

    def validate_class_availability
      profile_classes = profile['classes'].keys
      properties = profile['properties']
      available_on_classes = properties.keys.flat_map do |key|
        properties[key].fetch('available_on', nil)&.fetch('class', nil)
      end.compact.uniq

      classes = ((profile_classes + available_on_classes).uniq - required_classes).map { |klass| klass.gsub(/(?<=.)Resource$/, '') }

      invalid_classes = classes.filter_map do |klass|
        klass unless Hyrax.config.registered_curation_concern_types.include?(klass)
      end

      return if invalid_classes.empty?

      @errors << "Invalid classes: #{invalid_classes.join(', ')}."
    end

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

    def validate_core_metadata_properties
      core_metadata['attributes'].each do |property, config|
        next unless validate_property_exists(property)

        validate_property_multi_value(property, config)
        validate_property_indexing(property, config)
        validate_property_predicate(property, config)
      end
    end

    def core_metadata
      @core_metadata ||= YAML.safe_load(File.open(Hyrax::Engine.root.join('config', 'metadata', 'core_metadata.yaml'))).with_indifferent_access
    end

    def validate_property_exists(property)
      return true if profile['properties'][property].present?

      @errors << "Missing required property: #{property}."
      false
    end

    def validate_property_multi_value(property, config)
      return unless config.key?('multiple')
      return if profile.dig('properties', property, 'multi_value') == config['multiple']

      @errors << "Property '#{property}' must have multi_value set to #{config['multiple']}."
    end

    def validate_property_indexing(property, config)
      return unless config.key?('index_keys')

      profile_indexing = profile.dig('properties', property, 'indexing') || []
      missing_keys = config['index_keys'] - profile_indexing

      return if missing_keys.empty?

      @errors << "Property '#{property}' is missing required indexing: #{missing_keys.join(', ')}."
    end

    def validate_property_predicate(property, config)
      return unless config.key?('predicate')
      return if profile.dig('properties', property, 'property_uri') == config['predicate']

      @errors << "Property '#{property}' must have property_uri set to #{config['predicate']}."
    end
  end
end
