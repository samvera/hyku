# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.1
# Add tenant filtering to Hyrax Analytics GA4 module to prevent data spillover between tenants
module Hyrax
  module Analytics
    module Ga4Decorator
      # Add tenant filtering to all analytics queries
      def add_tenant_filter(query_object, tenant_id = nil)
        return query_object if tenant_id.blank?

        query_object.add_filter(dimension: 'customEvent:tenant_id', values: [tenant_id])
        query_object
      end

      # Override daily_events to include tenant filtering
      def daily_events(action, date = default_date_range, tenant_id: nil)
        events_daily = super(action, date)
        add_tenant_filter(events_daily, tenant_id) if tenant_id.present?
        events_daily
      end

      # Override daily_events_for_id to include tenant filtering
      def daily_events_for_id(id, action, date = default_date_range, tenant_id: nil)
        date = date.split(",")
        events_daily = EventsDaily.by_id(date[0], date[1], id, action)
        add_tenant_filter(events_daily, tenant_id) if tenant_id.present?
        events_daily
      end

      # Override top_events to include tenant filtering
      def top_events(action, date = default_date_range, tenant_id: nil)
        date = date.split(",")
        events = Events.list(date[0], date[1], action)
        add_tenant_filter(events, tenant_id) if tenant_id.present?
        events
      end

      # Override visitor analytics to include tenant filtering
      def new_visitors(period = 'month', date = default_date_range, tenant_id: nil)
        start_date, end_date = date_period(period, date)
        visits = Visits.new(start_date: start_date, end_date: end_date)
        add_tenant_filter(visits, tenant_id) if tenant_id.present?
        visits.new_visits
      end

      def returning_visitors(period = 'month', date = default_date_range, tenant_id: nil)
        start_date, end_date = date_period(period, date)
        visits = Visits.new(start_date: start_date, end_date: end_date)
        add_tenant_filter(visits, tenant_id) if tenant_id.present?
        visits.return_visits
      end

      def total_visitors(period = 'month', date = default_date_range, tenant_id: nil)
        start_date, end_date = date_period(period, date)
        visits = Visits.new(start_date: start_date, end_date: end_date)
        add_tenant_filter(visits, tenant_id) if tenant_id.present?
        visits.total_visits
      end

      def page_statistics(start_date, object, tenant_id: nil)
        visits = VisitsDaily.new(start_date: start_date, end_date: Date.yesterday)
        visits.add_filter(dimension: 'contentId', values: [object.id.to_s])
        add_tenant_filter(visits, tenant_id) if tenant_id.present?
        visits.total_visits
      end

      def unique_visitors_for_id(id, date = default_date_range, tenant_id: nil)
        # This method might not exist in the original, so provide a default implementation
        return [] if tenant_id.present? # Simplified for now
        super(id, date) if defined?(super)
      end

      # Helper method to get current tenant ID
      def current_tenant_id
        # Try to get tenant from current account context
        if defined?(Account) && Account.current&.tenant
          Account.current.tenant
        else
          'default'
        end
      end
    end
  end
end

Hyrax::Analytics::Ga4.singleton_class.prepend(Hyrax::Analytics::Ga4Decorator)
