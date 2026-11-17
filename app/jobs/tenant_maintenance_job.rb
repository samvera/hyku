# frozen_string_literal: true

class TenantMaintenanceJob < ApplicationJob
  queue_as :default

  non_tenant_job

  def perform
    Account.find_each(&:find_or_schedule_jobs)
    UploadsCleanupJob.perform_later if UploadsCleanupJob.enabled?
    TenantMaintenanceJob.set(wait_until: Date.tomorrow.midnight).perform_later
  end
end
