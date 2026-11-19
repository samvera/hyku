# frozen_string_literal: true

# Always define the module for Zeitwerk autoloading
module BlacklightAdvancedSearch
  module RenderConstraintsOverrideDecorator
    # OVERRIDE: BlacklightAdvancedSearch v7.0.0
    #
    # Blacklight 7.43 renders advanced search facet limits (f_inclusive) as constraints itself. The gem's
    # override renders them a second time, and building its "remove" link raised
    # "undefined method `delete' for nil": it rebuilds the params through Blacklight::SearchState and reads
    # them with symbol keys, but SearchState#to_h returns a plain Hash with string keys (the same cause as
    # AdvancedQueryParserDecorator). Every advanced search with a facet limit returned 500.
    #
    # Render the filters with Blacklight's own implementation only.
    #
    # TODO: Remove this override after upgrading to BlacklightAdvancedSearch v8.x.x
    def render_constraints_filters(my_params = params)
      Blacklight::RenderConstraintsHelperBehavior.instance_method(:render_constraints_filters).bind_call(self, my_params)
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
