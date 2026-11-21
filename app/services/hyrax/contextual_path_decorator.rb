# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to keep the chosen language on links to a work's members; Hyrax builds
# them outside the request, so they missed the locale param every other link carries
module Hyrax
  module ContextualPathDecorator
    def url_options
      return super if I18n.locale == I18n.default_locale

      super.merge(locale: I18n.locale)
    end
  end
end

Hyrax::ContextualPath.prepend Hyrax::ContextualPathDecorator
