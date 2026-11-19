# frozen_string_literal: true

# Always define the module for Zeitwerk autoloading
module BlacklightAdvancedSearch
  module RenderConstraintsOverrideDecorator
    # OVERRIDE: BlacklightAdvancedSearch v7.0.0
    #
    # Builds the "remove" link for an advanced search facet limit. The gem rebuilds the params through
    # Blacklight::SearchState and then reads them with symbol keys, but SearchState#to_h returns a plain
    # Hash with string keys, so my_params[:f_inclusive] was nil and every advanced search with a facet
    # limit (f_inclusive) raised "undefined method `delete' for nil" while rendering its constraints.
    # Same cause as AdvancedQueryParserDecorator.
    #
    # TODO: Remove this override after upgrading to BlacklightAdvancedSearch v8.x.x
    def remove_advanced_filter_group(field, my_params = params)
      return my_params unless my_params[:f_inclusive]

      my_params = Blacklight::SearchState.new(my_params, blacklight_config).to_h.with_indifferent_access
      my_params[:f_inclusive] = my_params[:f_inclusive].except(field)
      my_params.delete(:f_inclusive) if my_params[:f_inclusive].empty?
      my_params
    end
  end
end

# Only prepend if the version is less than 8.0.0
if defined?(BlacklightAdvancedSearch::VERSION) &&
   Gem::Version.new(BlacklightAdvancedSearch::VERSION) < Gem::Version.new('8.0.0') &&
   defined?(BlacklightAdvancedSearch::RenderConstraintsOverride)

  unless BlacklightAdvancedSearch::RenderConstraintsOverride.ancestors.include?(BlacklightAdvancedSearch::RenderConstraintsOverrideDecorator)
    BlacklightAdvancedSearch::RenderConstraintsOverride.prepend(BlacklightAdvancedSearch::RenderConstraintsOverrideDecorator)
  end
end
