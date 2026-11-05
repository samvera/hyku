# frozen_string_literal: true

module Hyku
  module HomePageThemesBehavior
    extend ActiveSupport::Concern

    included do
      around_action :inject_theme_views
    end

    # Needed for decorators
    prepended do
      around_action :inject_theme_views
    end

    def self.view_paths(theme)
      Hyku::Application.theme_view_path_roots.map { |root| File.join(root, 'app', 'views', 'themes', theme.to_s) }
    end

    # Add this method to prepend the theme views into the view_paths
    def inject_theme_views
      HomePageThemesBehavior.view_paths(home_page_theme).reverse_each { |path| prepend_view_path(path) } if home_page_theme && home_page_theme != 'default_home'
      yield
    end
  end
end
