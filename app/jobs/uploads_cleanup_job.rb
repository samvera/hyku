# frozen_string_literal: true

# Daily upload staging cleanup, enqueued by TenantMaintenanceJob when HYKU_SCHEDULE_UPLOADS_CLEANUP is on.
# Takes the same environment options as hyku:cleanup_uploads (including DRY_RUN). The worker that runs it
# must mount the uploads volume: tenants whose staging directory is not visible there are skipped.
class UploadsCleanupJob < ApplicationJob
  queue_as :default

  non_tenant_job

  def self.enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_SCHEDULE_UPLOADS_CLEANUP', false))
  end

  def perform
    UploadsCleanupService.new(**UploadsCleanupService.options_from_env).run
  end
end
