# frozen_string_literal: true

# OVERRIDE: Hyrax v5.3.0
# - inject the show theme's views when the file set page reloads its download link rows, so a
#   new link gets the same theme copy button as the rows the page first drew

module Hyrax
  module SingleUseLinksControllerDecorator
    extend ActiveSupport::Concern

    include Hyku::ShowThemesBehavior

    prepended do
      around_action :inject_link_rows_theme_views, only: :index
    end

    def inject_link_rows_theme_views(&block)
      return yield unless Hyku::ChromeThemes.show?(show_page_theme)

      inject_show_theme_views(&block)
    end
  end
end

Hyrax::SingleUseLinksController.prepend(Hyrax::SingleUseLinksControllerDecorator)
