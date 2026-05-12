# frozen_string_literal: true
module Hyrax
  module AccessibilityHazardsService
    extend Hyrax::AuthorityService

    authority_name 'accessibility_hazards'
    microdata_namespace 'accessibility_hazard_type.'
  end
end
