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
        # A theme registered with a `parent:` in home_themes.yml is a thin
        # variant: its own views win, unresolved renders fall through to the
        # parent theme, then to the default views. Parent paths are prepended
        # first so the variant's paths end up in front of them.
        #
        # No restore after yield: the prepended paths live on this controller
        # instance, which does not outlive the request. The restore this
        # method used to attempt (`view_paths=(original_paths)`) was a bare
        # local-variable assignment, so it never ran - and the instance
        # writer it claimed to call does not exist in Rails 7.
        [parent_home_page_theme, home_page_theme.to_s].compact.each do |theme|
          Hyku::Application.theme_view_path_roots.each do |root|
            home_theme_view_path = File.join(root, 'app', 'views', "themes", theme)
            prepend_view_path(home_theme_view_path)
          end
        end
      end
      yield
    end

    private

    def parent_home_page_theme
      themes = YAML.load_file(Hyku::Application.path_for('config/home_themes.yml'))
      themes.dig(home_page_theme.to_s, 'parent')
    rescue Errno::ENOENT
      nil
    end
  end
end
