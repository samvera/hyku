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
      validate_classes
      validate_title_multi_value
      validate_schema
      validate_label_prop
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
        @errors << <<~ERROR.strip
          Data: #{error['data']}
          Data pointer: #{error['data_pointer']}
          Schema: #{error['schema']}
          Schema pointer: #{error['schema_pointer']}
          Type: #{error['type']}
        ERROR
      end
    end

    def validate_required_classes
      missing_classes = required_classes - profile['classes'].keys
      return if missing_classes.empty?

      @errors << "Missing required classes: #{missing_classes.join(', ')}."
    end

    def validate_classes
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

    def validate_title_multi_value
      return if profile['properties']['title']['multi_value'] == true

      @errors << "Title must be multi value."
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
  end
end
