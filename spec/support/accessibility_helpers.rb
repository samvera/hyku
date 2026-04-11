# frozen_string_literal: true

require 'axe-rspec'

module HykuAccessibility
  module AxeConfiguration
    # Per docs/accessibility/wcag-2.1-aa-traceability-matrix.yaml
    TAGS = [:wcag2a, :wcag2aa, :wcag21aa].freeze
    MAIN_LANDMARK_SELECTOR = '#content-wrapper'
  end

  module Helpers
    # Full WCAG 2.1 AA-oriented scan of Hyku's primary landmark (Hyrax layout).
    def expect_hyku_primary_content_axe_clean
      expect(page).to be_axe_clean
        .according_to(*AxeConfiguration::TAGS)
        .within(AxeConfiguration::MAIN_LANDMARK_SELECTOR)
    end
  end
end

RSpec.configure do |config|
  config.include HykuAccessibility::Helpers, a11y: true
end
