# frozen_string_literal: true

module Hyku
  module AccountPageThemesBehavior
    extend ActiveSupport::Concern

    PAGES = %w[sessions passwords registrations single_signon].freeze

    included do
      around_action :inject_account_page_theme_views, if: :themed_account_page?
      helper_method :themed_account_page?
    end

    private

    def themed_account_page?
      devise_controller? && PAGES.include?(controller_name) && Hyku::ChromeThemes.account?(home_page_theme)
    end

    def inject_account_page_theme_views
      HomePageThemesBehavior.view_paths(home_page_theme).reverse_each { |path| prepend_view_path(path) }
      yield
    end
  end
end
