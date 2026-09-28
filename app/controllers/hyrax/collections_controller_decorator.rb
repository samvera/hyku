# frozen_string_literal: true

# OVERRIDE: Hyrax v5.3.0
# - inject the show theme's views so the collection show page gets the theme's
#   chrome, the way the work show page already does

module Hyrax
  module CollectionsControllerDecorator
    extend ActiveSupport::Concern

    include Hyku::ChromeShowThemesBehavior
  end
end

Hyrax::CollectionsController.prepend(Hyrax::CollectionsControllerDecorator)
