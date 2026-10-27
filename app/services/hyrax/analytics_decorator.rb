# frozen_string_literal: true

# OVERRIDE Hyrax 5.3.0 to scope Hyrax::Analytics.config to the request, since Hyku writes
# per-tenant IDs into it and Hyrax shares one copy across every thread
module Hyrax
  module AnalyticsDecorator
    def config
      RequestStore.store[:hyrax_analytics_config] ||= super.class.load_from_yaml
    end
  end
end

Hyrax::Analytics.singleton_class.prepend(Hyrax::AnalyticsDecorator)
