# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to facet each dashboard field on its labels wherever the catalog
# does, which the metadata profile decides per request (docs/controlled-vocabularies.md)
module Hyrax
  module MyControllerDecorator
    def blacklight_config
      @blacklight_config ||= super.deep_copy.tap do |config|
        catalog_config = ::CatalogController.new.blacklight_config
        config.facet_fields = config.facet_fields.to_h do |key, field|
          label_facet = Hyku::LabelFacet.for(catalog_config, key)
          next [key, field] if label_facet == key

          [label_facet, label_facet_config(field, label_facet)]
        end.with_indifferent_access
      end
    end

    private

    def label_facet_config(field, label_facet)
      field.dup.tap do |labeled|
        labeled.key = labeled.field = label_facet
        labeled.label = field.display_label('facet')
      end
    end
  end
end

Hyrax::MyController.prepend(Hyrax::MyControllerDecorator)
