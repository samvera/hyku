# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.1 to dd tenant-specific analytics filtering for
# individual work stats to prevent data spillover between tenants
module Hyrax
  module StatsControllerDecorator
    def work
      tenant_id = current_account&.tenant || 'default'

      @document = ::SolrDocument.find(params[:id])
      @pageviews = Hyrax::Analytics.daily_events_for_id(@document.id, 'work-view', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
      @downloads = Hyrax::Analytics.daily_events_for_id(@document.id, 'file-set-in-work-download', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
    end
  end
end

Hyrax::StatsController.prepend(Hyrax::StatsControllerDecorator)
