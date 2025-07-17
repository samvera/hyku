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
      end
    end

    private

    attr_reader :profile, :errors

    def core_metadata
      @core_metadata ||= YAML.safe_load(File.open(Hyrax::Engine.root.join('config', 'metadata', 'core_metadata.yaml'))).with_indifferent_access
    end

    def validate_property_exists(property)
      return true if profile['properties'][property].present?

      errors << "Missing required property: #{property}."
      false
    end

    def validate_property_multi_value(property, config)
      return unless config.key?('multiple')
      return if profile.dig('properties', property, 'multi_value') == config['multiple']

      errors << "Property '#{property}' must have multi_value set to #{config['multiple']}."
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
  end
end
