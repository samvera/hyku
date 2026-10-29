# frozen_string_literal: true

module ThemeLabelHelper
  def theme_values(object, field)
    theme_value_pairs(object, field).map(&:last)
  end

  def theme_value_pairs(object, field)
    stored = Array(object.try(field))
    return stored.zip(Array(object.display_values_for(field))) if object.respond_to?(:display_values_for)

    labels = Array(object.try(:[], Hyrax::ControlledVocabularyFieldValues.label_key("#{field}_tesim")))
    return stored.zip(stored) unless labels.size == stored.size

    stored.zip(stored.zip(labels).map { |value, label| label.presence || value })
  end

  def theme_facet_list(object, field, empty_message)
    pairs = theme_value_pairs(object, field)
    return empty_message if pairs.empty?

    id_facet = "#{field}_sim"
    facet = ThemeHomepage.facet_field(blacklight_config, id_facet)
    links = pairs.map do |stored, shown|
      link_to(shown, main_app.search_catalog_path(search_state.add_facet_params_and_redirect(facet, facet == id_facet ? stored : shown)))
    end
    safe_join(links, ', ')
  end
end
