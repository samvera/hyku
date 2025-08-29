# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.1 to add tenant-specific analytics filtering for
# collection reports to prevent data spillover between tenants
module Hyrax
  module Admin
    module Analytics
      module CollectionReportsControllerDecorator
        def index
          return unless Hyrax.config.analytics_reporting?

          begin
            tenant_id = current_account&.tenant || 'default'

            @pageviews = Hyrax::Analytics.daily_events('collection-page-view', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
            @work_page_views = Hyrax::Analytics.daily_events('work-in-collection-view', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
            @downloads = Hyrax::Analytics.daily_events('work-in-collection-download', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
            @all_top_collections = Hyrax::Analytics.top_events('work-in-collection-view', date_range, tenant_id: tenant_id)
            @top_collections = paginate(@all_top_collections, rows: 10)
            @top_downloads = Hyrax::Analytics.top_events('work-in-collection-download', date_range, tenant_id: tenant_id)
            @top_collection_pages = Hyrax::Analytics.top_events('collection-page-view', date_range, tenant_id: tenant_id)
          rescue Google::Cloud::PermissionDeniedError => e
            handle_analytics_permission_error(e)
          rescue Google::Cloud::InvalidArgumentError => e
            handle_analytics_invalid_argument_error(e)
          rescue StandardError => e
            handle_analytics_generic_error(e)
          end

          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        def show
          return unless Hyrax.config.analytics_reporting?

          begin
            tenant_id = current_account&.tenant || 'default'

            @document = ::SolrDocument.find(params[:id])
            @pageviews = Hyrax::Analytics.daily_events_for_id(@document.id, 'collection-page-view', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
            @work_page_views = Hyrax::Analytics.daily_events_for_id(@document.id, 'work-in-collection-view', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
            @uniques = Hyrax::Analytics.unique_visitors_for_id(@document.id, Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
            @downloads = Hyrax::Analytics.daily_events_for_id(@document.id, 'work-in-collection-download', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
          rescue Google::Cloud::PermissionDeniedError => e
            handle_analytics_permission_error(e)
          rescue Google::Cloud::InvalidArgumentError => e
            handle_analytics_invalid_argument_error(e)
          rescue StandardError => e
            handle_analytics_generic_error(e)
          end

          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        private

        def handle_analytics_permission_error(error)
          @analytics_error = "Analytics Unavailable"
          @analytics_details = extract_google_api_message(error.message)
        end

        def handle_analytics_invalid_argument_error(error)
          @analytics_error = "Analytics Configuration Error"
          @analytics_details = extract_custom_dimension_message(error.message)
        end

        def handle_analytics_generic_error(error)
          @analytics_error = "Analytics Temporarily Unavailable"
          @analytics_details = "Unable to load analytics data. Please try again later or contact your administrator."
          Rails.logger.error "Analytics error in collection reports: #{error.class} - #{error.message}"
        end

        def extract_google_api_message(message)
          if message.include?("has not been used in project") || message.include?("it is disabled")
            project_id = message.match(/project (\w+)/i)&.captures&.first
            if project_id
              "The Google Analytics Data API is not enabled for this project. " \
              "Enable the Google Analytics Data API by visiting: " \
              "https://console.developers.google.com/apis/api/analyticsdata.googleapis.com/overview?project=#{project_id}"
            else
              "The Google Analytics Data API is not enabled. Please enable it in the Google Cloud Console."
            end
          else
            "There was a permission error accessing Google Analytics data. Please verify your service account has proper access."
          end
        end

        def extract_custom_dimension_message(message)
          if message.include?("tenant_id") && message.include?("not a valid dimension")
            "The tenant_id custom dimension is missing from your Google Analytics 4 property. " \
            "This dimension is required for multi-tenant analytics isolation."
          else
            "There was a configuration error with Google Analytics dimensions. Please check your GA4 property setup."
          end
        end
      end
    end
  end
end

Hyrax::Admin::Analytics::CollectionReportsController.prepend(Hyrax::Admin::Analytics::CollectionReportsControllerDecorator)
