# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to link a show page value through the facet the catalog uses for it, or show
#   it unlinked when the catalog registers no facet for it
# TEMPORARY: delete when samvera/hyrax#7724 is in the bundled Hyrax
module Hyrax
  module HyraxHelperBehaviorDecorator
    def link_to_value_facet(value, label, field)
      label_facet = registered_label_facet(field) if label.present?
      return ERB::Util.html_escape(label.presence || value) unless label_facet || registered_facet?(field)

      facet, queried = label_facet ? [label_facet, label] : [field, value]
      path = main_app.search_catalog_path(search_state.add_facet_params_and_redirect(facet, queried))
      link_to(label.presence || value, path)
    end

    private

    def registered_facet?(field)
      catalog_blacklight_config.facet_fields.key?(field.to_s)
    end

    def registered_label_facet(field)
      label_facet = Hyrax::ControlledVocabularyFieldValues.label_key(field)
      return if label_facet == field.to_s

      label_facet if catalog_blacklight_config.facet_fields.key?(label_facet)
    end

    def catalog_blacklight_config
      @catalog_blacklight_config ||= ::CatalogController.new.blacklight_config
    end
  end
end

Hyrax::HyraxHelperBehavior.prepend(Hyrax::HyraxHelperBehaviorDecorator)
