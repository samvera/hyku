# frozen_string_literal: true

# OVERRIDE Hyrax 5.3.0 to search for the term it shows as written; the route helper
# already escapes the query, so escaping it first searched for "Allen &amp; Ginter"

module Hyrax
  module Renderers
    module LinkedAttributeRendererDecorator
      private

      def search_path(value)
        Rails.application.routes.url_helpers.search_catalog_path(search_field:, q: search_term(value), locale: I18n.locale)
      end
    end
  end
end

Hyrax::Renderers::LinkedAttributeRenderer.prepend(Hyrax::Renderers::LinkedAttributeRendererDecorator)
