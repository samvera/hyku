# frozen_string_literal: true

# OVERRIDE from Hyrax v5.0.1 to Add tenant_id to analytics calls
module Hyrax
  module Admin
    module Analytics
      module WorkReportsControllerDecorator
        def index
          return unless Hyrax.config.analytics_reporting?

          begin
            tenant_id = current_account&.tenant || 'default'
            @accessible_works ||= accessible_works
            @accessible_file_sets ||= accessible_file_sets
            @works_count = @accessible_works.count
            @top_works = paginate(top_works_list, rows: 10)
            @top_file_set_downloads = paginate(top_files_list, rows: 10)
            # rubocop:disable Style/ParallelAssignment
            if current_user.ability.admin?
              @pageviews, @downloads = Hyrax::Analytics.daily_events('work-view', tenant_id: tenant_id),
                                       Hyrax::Analytics.daily_events('file-set-download', tenant_id: tenant_id)
            end
            # rubocop:enable Style/ParallelAssignment
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
          begin
            tenant_id = current_account&.tenant || 'default'
            @pageviews = Hyrax::Analytics.daily_events_for_id(@document.id, 'work-view', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
            @uniques = Hyrax::Analytics.unique_visitors_for_id(@document.id, Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
            @downloads = Hyrax::Analytics.daily_events_for_id(@document.id, 'file_set_in_work_download', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
            @files = paginate(@document._source["member_ids_ssim"], rows: 5)
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
          Rails.logger.error "Analytics error in work reports: #{error.class} - #{error.message}"
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

Hyrax::Admin::Analytics::WorkReportsController.prepend(Hyrax::Admin::Analytics::WorkReportsControllerDecorator)
