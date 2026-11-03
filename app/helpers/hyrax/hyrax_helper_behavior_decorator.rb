# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to link a show page value through the facet the catalog uses for it
# TEMPORARY: delete when samvera/hyrax#7724 is in the bundled Hyrax
module Hyrax
  module HyraxHelperBehaviorDecorator
    def link_to_value_facet(value, label, field)
      label_facet = registered_label_facet(field) if label.present?
      facet, queried = label_facet ? [label_facet, label] : [field, value]
      path = main_app.search_catalog_path(search_state.add_facet_params_and_redirect(facet, queried))
      link_to(label.presence || value, path)
    end

    private

    def registered_label_facet(field)
      label_facet = Hyrax::ControlledVocabularyFieldValues.label_key(field)
      return if label_facet == field.to_s || !respond_to?(:blacklight_config)

      label_facet if blacklight_config.facet_fields.key?(label_facet)
    end
  end
end

Hyrax::HyraxHelperBehavior.prepend(Hyrax::HyraxHelperBehaviorDecorator)
