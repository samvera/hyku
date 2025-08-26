# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.1
# Add tenant-specific analytics filtering for work reports to prevent data spillover between tenants
module Hyrax
  module Admin
    module Analytics
      module WorkReportsControllerDecorator
        def index
          return unless Hyrax.config.analytics_reporting?

          tenant_id = current_account&.tenant || 'default'

          @accessible_works ||= accessible_works
          @works_count = @accessible_works.size
          @top_works = paginate(top_analytics_works(tenant_id), rows: 10)
          @top_file_set_downloads = paginate(top_files_list(tenant_id), rows: 10)

          if current_user.ability.admin?
            @pageviews = Hyrax::Analytics.daily_events('work-view', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
            @downloads = Hyrax::Analytics.daily_events('file-set-download', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
          end

          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        def show
          tenant_id = current_account&.tenant || 'default'

          @pageviews = Hyrax::Analytics.daily_events_for_id(@document.id, 'work-view', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
          @uniques = Hyrax::Analytics.unique_visitors_for_id(@document.id, Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
          @downloads = Hyrax::Analytics.daily_events_for_id(@document.id, 'file_set_in_work_download', Hyrax::Analytics.default_date_range, tenant_id: tenant_id)
          @files = paginate(@document._source["member_ids_ssim"], rows: 5)

          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        private

        def top_analytics_works(tenant_id = nil)
          @top_analytics_works ||= Hyrax::Analytics.top_events('work-view', date_range, tenant_id: tenant_id)
        end

        def top_analytics_downloads(tenant_id = nil)
          @top_analytics_downloads ||= Hyrax::Analytics.top_events('file-set-in-work-download', date_range, tenant_id: tenant_id)
        end

        def top_analytics_file_sets(tenant_id = nil)
          @top_analytics_file_sets ||= Hyrax::Analytics.top_events('file-set-download', date_range, tenant_id: tenant_id)
        end

        def top_files_list(tenant_id = nil)
          @top_files_list ||= top_analytics_downloads(tenant_id).flat_map do |work_id, _count|
            work = accessible_works.detect { |w| w.id == work_id }
            next unless work

            work._source["member_ids_ssim"]&.map do |file_id|
              [file_id, work_id, work._source["title_tesim"]&.first]
            end
          end.compact
        end
      end
    end
  end
end

Hyrax::Admin::Analytics::WorkReportsController.prepend(Hyrax::Admin::Analytics::WorkReportsControllerDecorator)
