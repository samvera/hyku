# frozen_string_literal: true
module Hyrax
  module AccessibilityFeaturesService
    extend Hyrax::AuthorityService

    authority_name 'accessibility_features'
    microdata_namespace 'accessibility_feature_type.'
  end
end
