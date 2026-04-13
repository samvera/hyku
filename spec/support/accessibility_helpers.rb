# frozen_string_literal: true

require 'axe-rspec'

module HykuAccessibility
  module AxeConfiguration
    # Per docs/accessibility/wcag-2.1-aa-traceability-matrix.yaml
    TAGS = [:wcag2a, :wcag2aa, :wcag21aa].freeze
    MAIN_LANDMARK_SELECTOR = '#content-wrapper'
    MASTHEAD_SELECTOR = '#masthead'
  end

  module Helpers
    # Full WCAG 2.1 AA-oriented scan of Hyku's primary landmark (Hyrax layout).
    def expect_hyku_primary_content_axe_clean
      expect(page).to be_axe_clean
        .according_to(*AxeConfiguration::TAGS)
        .within(AxeConfiguration::MAIN_LANDMARK_SELECTOR)
      # Capture here: after hooks run too late (session can already be about:blank for remote Chrome).
      # Do not use RSpec.current_example here — it is often nil inside included helpers after matchers.
      HykuAccessibility::A11yArtifacts.write_for_example(@hyku_a11y_rspec_example) if ENV['A11Y_ARTIFACTS'].present?
    end

    # Global nav chrome (separate from #content-wrapper). May surface third-party or theme noise;
    # document exclusions in evidence notes if you add .excluding(...).
    def expect_hyku_masthead_axe_clean
      expect(page).to be_axe_clean
        .according_to(*AxeConfiguration::TAGS)
        .within(AxeConfiguration::MASTHEAD_SELECTOR)
      HykuAccessibility::A11yArtifacts.write_for_example(@hyku_a11y_rspec_example) if ENV['A11Y_ARTIFACTS'].present?
    end
  end
end

RSpec.configure do |config|
  config.include HykuAccessibility::Helpers, a11y: true
end
