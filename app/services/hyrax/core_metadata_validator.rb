# frozen_string_literal: true

module Hyrax
  ##
  # @api private
  #
  # Validates the core metadata properties of a flexible metadata profile.
  class CoreMetadataValidator
    ##
    # @param profile [Hash] the flexible metadata profile
    # @param errors [Array<String>] an array to append errors to
    def initialize(profile:, errors:)
      @profile = profile
      @errors = errors
    end

    def validate!
      core_metadata['attributes'].each do |property, config|
        next unless validate_property_exists(property)

        validate_property_multi_value(property, config)
        validate_property_indexing(property, config)
        validate_property_predicate(property, config)
        validate_property_available_on(property)
        validate_property_cardinality(property, config)
      end
    end

    private

    attr_reader :profile, :errors

    def core_metadata
      @core_metadata ||= YAML.safe_load(File.read(Hyrax::Engine.root.join('config', 'metadata', 'core_metadata.yaml'))).with_indifferent_access
    end

    def defined_classes
      @defined_classes ||= profile['classes'].keys
    end

    def validate_property_exists(property)
      return true if profile['properties'][property].present?

      errors << "Missing required property: #{property}."
      false
    end

    def validate_property_multi_value(property, config)
      return unless config.key?("multiple")

      property_config = profile.dig('properties', property) || {}

      required_data_type = config['multiple'] ? 'array' : 'string'

      actual_data_type = determine_data_type_from_config(property_config)

      return if actual_data_type == required_data_type

      errors << "Property '#{property}' must have data_type set to '#{required_data_type}'."
    end

    def determine_data_type_from_config(property_config)
      if property_config['data_type']
        property_config['data_type']
      elsif property_config['multi_value']
        'array'
      else
        'string'
      end
    end

    def validate_property_indexing(property, config)
      return unless config.key?('index_keys')

      profile_indexing = profile.dig('properties', property, 'indexing') || []
      missing_keys = config['index_keys'] - profile_indexing

      return if missing_keys.empty?

      errors << "Property '#{property}' is missing required indexing: #{missing_keys.join(', ')}."
    end

    def validate_property_predicate(property, config)
      return unless config.key?('predicate')
      return if profile.dig('properties', property, 'property_uri') == config['predicate']

      errors << "Property '#{property}' must have property_uri set to #{config['predicate']}."
    end

    def validate_property_available_on(property)
      available_on_classes = profile.dig('properties', property, 'available_on', 'class') || []
      missing_classes = defined_classes - available_on_classes

      return if missing_classes.empty?
      errors << "Property '#{property}' must be available on all classes, but is missing from: #{missing_classes.join(', ')}."
    end

    def validate_property_cardinality(property, _config)
      # Ensure that the `title` property is always required by enforcing
      # a cardinality minimum of at least 1.  According to the M3 profile
      # specification, `cardinality.minimum` > 0 is interpreted as
      # "required".
      return unless property.to_s == 'title'

      minimum = profile.dig('properties', property, 'cardinality', 'minimum')

      # Treat missing `cardinality` or `minimum` as 0 (i.e., not required).
      required = minimum.to_i.positive?
      return if required

      errors << "Property 'title' must have a cardinality minimum of at least 1."
    end
  end
end
