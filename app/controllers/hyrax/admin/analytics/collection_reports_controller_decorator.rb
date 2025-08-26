# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.1
# Add tenant-specific analytics filtering for collection reports to prevent data spillover between tenants
module Hyrax
  module Admin
    module Analytics
      module CollectionReportsControllerDecorator
        def index
          return unless Hyrax.config.analytics_reporting?

          tenant_id = current_account&.tenant || 'default'

          @pageviews = Hyrax::Analytics.daily_events('collection-page-view', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
          @work_page_views = Hyrax::Analytics.daily_events('work-in-collection-view', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
          @downloads = Hyrax::Analytics.daily_events('work-in-collection-download', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
          @all_top_collections = Hyrax::Analytics.top_events('work-in-collection-view', date_range, tenant_id: tenant_id)
          @top_collections = paginate(@all_top_collections, rows: 10)
          @top_downloads = Hyrax::Analytics.top_events('work-in-collection-download', date_range, tenant_id: tenant_id)
          @top_collection_pages = Hyrax::Analytics.top_events('collection-page-view', date_range, tenant_id: tenant_id)

          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        def show
          return unless Hyrax.config.analytics_reporting?

          tenant_id = current_account&.tenant || 'default'

          @document = ::SolrDocument.find(params[:id])
          @pageviews = Hyrax::Analytics.daily_events_for_id(@document.id, 'collection-page-view', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
          @work_page_views = Hyrax::Analytics.daily_events_for_id(@document.id, 'work-in-collection-view', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
          @uniques = Hyrax::Analytics.unique_visitors_for_id(@document.id, Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
          @downloads = Hyrax::Analytics.daily_events_for_id(@document.id, 'work-in-collection-download', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)

          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end
      end
    end
  end
end

Hyrax::Admin::Analytics::CollectionReportsController.prepend(Hyrax::Admin::Analytics::CollectionReportsControllerDecorator)
