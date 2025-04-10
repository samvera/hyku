# frozen_string_literal: true

# OVERRIDE Blacklight 6.7.0 to enable markdown in the facets

require_dependency Blacklight::Engine.root.join('app', 'helpers', 'blacklight', 'facets_helper_behavior').to_s

Blacklight::FacetsHelperBehavior.class_eval do
  # OVERRIDE to enable markdown in the facet list
  def render_facet_limit_list(paginator, facet_field, wrapping_element = :li)
    safe_join(paginator.items.map { |item| markdown(render_facet_item(facet_field, item)) }.compact.map { |item| content_tag(wrapping_element, item) })
  end
end
