# frozen_string_literal: true

# OVERRIDE: Blacklight v7.35.0 to allow the Cultural Repository theme to add facets to the homepage

module Blacklight
  module ControllerDecorator
    def search_facet_path(options = {})
      opts = search_state
             .to_h
             .merge(action: "facet", only_path: true)
             .merge(options)
             .except(:page)

      opts[:action] = "index" if self.class == Hyrax::HomepageController # OVERRIDE

      url_for opts
    end
  end
end

Blacklight::Controller.prepend(Blacklight::ControllerDecorator)
