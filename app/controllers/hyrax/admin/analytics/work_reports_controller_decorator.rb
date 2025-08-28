# frozen_string_literal: true

# OVERRIDE from Hyrax v5.0.1 to Add tenant_id to analytics calls
module Hyrax
  module Admin
    module Analytics
      module WorkReportsControllerDecorator
        def index
          return unless Hyrax.config.analytics_reporting?

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
          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        def show
          tenant_id = current_account&.tenant || 'default'
          @pageviews = Hyrax::Analytics.daily_events_for_id(@document.id, 'work-view', tenant_id: tenant_id)
          @uniques = Hyrax::Analytics.unique_visitors_for_id(@document.id, tenant_id: tenant_id)
          @downloads = Hyrax::Analytics.daily_events_for_id(@document.id, 'file_set_in_work_download', tenant_id: tenant_id)
          @files = paginate(@document._source["member_ids_ssim"], rows: 5)
          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end
      end
    end
  end
end

Hyrax::Admin::Analytics::WorkReportsController.prepend(Hyrax::Admin::Analytics::WorkReportsControllerDecorator)
