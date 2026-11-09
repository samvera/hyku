# frozen_string_literal: true

module Hyku
  # Injects the show theme's views on the pages this behavior is prepended to,
  # for the themes whose chrome was built for them. Works controllers register
  # ShowThemesBehavior directly instead, since the work show has carried every
  # show theme since long before the chrome themes existed.
  module ChromeShowThemesBehavior
    extend ActiveSupport::Concern

    include Hyku::ShowThemesBehavior

    prepended do
      around_action :inject_chrome_theme_views, only: :show
    end

    def inject_chrome_theme_views(&block)
      return yield unless Hyku::ChromeThemes.show?(show_page_theme)

      inject_show_theme_views(&block)
    end
  end
end
