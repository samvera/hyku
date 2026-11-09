# frozen_string_literal: true

# OVERRIDE blacklight_range_limit 8.5.0 to build the "view distribution" link against the catalog.
#   Upstream calls url_for(action: 'range_limit') without a controller, so it resolves against the
#   current one.  Themes that render facets on the homepage (heritage, cultural_repository) then ask
#   for hyrax/homepage#range_limit, which has no route, and the homepage raises a 500 as soon as a
#   range facet has values.  Same reason Hyrax::HomepageController overrides search_facet_path.
module BlacklightRangeLimit
  module RangeFacetComponentDecorator
    def range_limit_url(options = {})
      super(options.merge(controller: '/catalog'))
    end
  end
end

BlacklightRangeLimit::RangeFacetComponent.prepend(BlacklightRangeLimit::RangeFacetComponentDecorator)
