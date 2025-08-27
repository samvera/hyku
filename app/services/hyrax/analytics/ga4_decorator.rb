# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.1
# This override modifies the Hyrax Google Analytics 4 reporting services to be tenant-aware.
# It ensures that when the analytics dashboard is viewed within a tenant, it only displays
# data specific to that tenant by adding a filter for the 'tenant_id' custom dimension.
module Hyrax
  module Analytics
    module Ga4Decorator
      # A mapping of Hyrax event names to the custom dimension used in Google Analytics.
      EVENT_DIMENSION_MAP = {
        'work-view' => 'customEvent:contentId',
        'collection-page-view' => 'customEvent:contentId',
        'work-in-collection-view' => 'customEvent:collectionId',
        'work-in-collection-download' => 'customEvent:collectionId'
      }.freeze
      private_constant :EVENT_DIMENSION_MAP

      # Overrides the original daily_events to filter by tenant_id.
      def daily_events(action, date = default_date_range, tenant_id: nil)
        original_results = super(action, date)
        return original_results unless tenant_id
        add_tenant_filter(original_results, tenant_id)
      end

      # Overrides the original daily_events_for_id to filter by tenant_id.
      def daily_events_for_id(id, action, date = default_date_range, tenant_id: nil)
        original_results = super(id, action, date)
        return original_results unless tenant_id
        add_tenant_filter(original_results, tenant_id)
      end

      # Overrides the original top_events to filter by tenant_id.
      def top_events(action, date = default_date_range, tenant_id: nil)
        date_parts = date.is_a?(String) ? date.split(',') : date
        query = Hyrax::Analytics::Ga4::Events.new(start_date: date_parts[0], end_date: date_parts[1])
        query.add_filter(dimension: 'eventName', values: [action])
        query.add_tenant_filter(tenant_id) if tenant_id

        # The dimension for top events varies based on the action being queried.
        dimension = EVENT_DIMENSION_MAP.fetch(action, 'customEvent:contentId')
        query.top_results(dimension: dimension)
      end

      private

      # A helper method to add the tenant filter to a query object.
      def add_tenant_filter(query_object, tenant_id)
        query_object.add_filter(dimension: 'customEvent:tenant_id', values: [tenant_id])
      end
    end
  end
end

# The base class for Google Analytics 4 queries.
# This is being extended to include a tenant filtering method.
class Hyrax::Analytics::Ga4::Base
  def add_tenant_filter(tenant_id)
    add_filter(dimension: 'customEvent:tenant_id', values: [tenant_id])
  end
end

Hyrax::Analytics::Ga4.singleton_class.prepend(Hyrax::Analytics::Ga4Decorator)

# Also prepend to the main Hyrax::Analytics module to ensure the methods are available there too
Hyrax::Analytics.singleton_class.prepend(Hyrax::Analytics::Ga4Decorator)

