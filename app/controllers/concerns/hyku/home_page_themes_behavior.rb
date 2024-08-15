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

    # Add this method to prepend the theme views into the view_paths
    def inject_theme_views
      if home_page_theme && home_page_theme != 'default_home'
        original_paths = view_paths
        Hyku::Application.theme_view_path_roots.each do |root|
          home_theme_view_path = File.join(root, 'app', 'views', "themes", home_page_theme.to_s)
          prepend_view_path(home_theme_view_path)
        end
        yield
        # rubocop:disable Lint/UselessAssignment, Layout/SpaceAroundOperators, Style/RedundantParentheses
        # Do NOT change this line. This is calling the Rails view_paths=(paths) method and not a variable assignment.
        view_paths=(original_paths)
        # rubocop:enable Lint/UselessAssignment, Layout/SpaceAroundOperators, Style/RedundantParentheses
      else
        yield
      end
    end
  end
end
