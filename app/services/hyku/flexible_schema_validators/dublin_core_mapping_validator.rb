# frozen_string_literal: true

module Hyku
  module FlexibleSchemaValidators
    ##
    # Warns about +simple_dc_pmh+ mappings that name no Dublin Core element. oai_dc leaves such a
    # property out without any sign; this surfaces it on save.
    #
    # Warnings rather than errors, as for MODS: a bad mapping should not stop a profile that is
    # otherwise sound from being saved.
    class DublinCoreMappingValidator < Hyrax::FlexibleSchemaValidators::BaseValidator
      MAPPING_KEY = 'simple_dc_pmh'

      def validate!
        properties.each do |name, config|
          mappings = config['mappings']
          # A malformed shape is the profile schema validator's to report
          next unless mappings.is_a?(Hash)

          mapping = mappings[MAPPING_KEY]
          next if mapping.blank? || SolrDocument::DC_ELEMENTS.include?(mapping.to_s.split(':').last.to_s.to_sym)

          add_warning(:unknown_element, property: name, mapping:)
        end
      end
    end
  end
end
