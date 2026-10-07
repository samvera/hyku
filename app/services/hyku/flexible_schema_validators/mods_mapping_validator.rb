# frozen_string_literal: true

module Hyku
  module FlexibleSchemaValidators
    ##
    # Warns about +mods_oai_pmh+ mappings that MODS records cannot use. The OAI-PMH feed leaves
    # such a property out and logs it only when a record is rendered; this surfaces it on save.
    #
    # Warnings rather than errors: MODS is an opt-in feed, and a bad mapping should not stop a
    # profile that is otherwise sound from being saved.
    class ModsMappingValidator < Hyrax::FlexibleSchemaValidators::BaseValidator
      def validate!
        properties.each do |name, config|
          mappings = config['mappings']
          # A malformed shape is the profile schema validator's to report
          next unless mappings.is_a?(Hash)

          mapping = mappings[Hyku::Mods::MAPPING_KEY]
          next if mapping.blank?

          check(name, mapping)
        end
      end

      private

      def check(name, mapping)
        path = Hyku::Mods::MappingPath.parse(mapping)
        return add_warning(:unknown_element, property: name, mapping:, element: path.steps.first.name) unless path.top_level?

        error = path.schema_error
        add_warning(:schema_mismatch, property: name, mapping:, error:) if error
      rescue Hyku::Mods::MappingPath::InvalidPath
        add_warning(:unsupported_syntax, property: name, mapping:)
      end
    end
  end
end
