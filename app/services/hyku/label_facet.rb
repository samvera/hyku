# frozen_string_literal: true

module Hyku
  module LabelFacet
    def self.for(config, field)
      label_facet = Hyrax::ControlledVocabularyFieldValues.label_key(field)
      config.facet_fields.key?(label_facet) ? label_facet : field
    end
  end
end
