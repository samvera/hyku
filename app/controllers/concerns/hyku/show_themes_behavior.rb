# frozen_string_literal: true

module Hyku
  # Prepends the show theme's view path, the way HomePageThemesBehavior does for
  # the home theme. The lookup context belongs to the request, so the paths go
  # with it and there is nothing to put back. Each controller registers its own
  # around_action over this method, since the work show wants it for every show
  # theme and the pages this branch adds want it only for the chrome themes.
  module ShowThemesBehavior
    extend ActiveSupport::Concern

    def inject_show_theme_views
      if show_page_theme && show_page_theme != 'default_show'
        Hyku::Application.theme_view_path_roots.each do |root|
          prepend_view_path(File.join(root, 'app', 'views', 'themes', show_page_theme.to_s))
        end
      end
      yield
    end
  end
end
