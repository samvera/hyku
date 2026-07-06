# frozen_string_literal: true

# Nightly reset for public demo (sandbox) tenants. One of these runs per
# flagged tenant. Account#find_or_schedule_jobs registers it, so tenant
# creation, application boot, and the daily TenantMaintenanceJob pass all
# keep the chain alive without any external scheduler.
#
# Configuration comes from the environment so deployments wire it without
# code changes:
#
#   DEMO_SEED_CSV_PATH  path to the Bulkrax seed CSV to re-import after the
#                       wipe; a %{tenant} placeholder expands to the account
#                       name (optional; without it the reset restores an
#                       empty but branded tenant)
#   DEMO_KEEP_USERS     comma-separated emails that survive resets in
#                       addition to superadmins (optional)
#   DEMO_IMPORT_USER    email of the user that owns the seed import (optional)
#   DEMO_HEALTH_CHECK   name of a class responding to .call(account) run
#                       after each reset (optional)
class DemoTenantResetJob < ApplicationJob
  # ApplicationJob's retry_on swallows the final exception silently; a
  # permanently failing nightly reset must be loud instead. On permanent
  # failure the tomorrow chain is deliberately not re-enqueued: the daily
  # TenantMaintenanceJob pass re-seeds it through find_or_schedule_jobs, and
  # the stale last_reset_at makes the failure visible.
  retry_on StandardError, wait: :polynomially_longer, attempts: 3 do |job, exception|
    Rails.logger.error(
      "[DemoTenantReset] job=#{job.class.name} tenant=#{job.tenant || Apartment::Tenant.current} " \
      "failed permanently: #{exception.class}: #{exception.message}"
    )
    Sentry.capture_exception(exception) if defined?(Sentry)
  end

  def perform
    account = current_account
    unless account&.public_demo_tenant?
      logger.info("[DemoTenantReset] tenant=#{current_tenant} is not a public demo tenant; ending nightly chain")
      return
    end

    DemoTenantResetService.new(account:, **service_options(account)).reset!
    self.class.set(wait_until: Date.tomorrow.midnight).perform_later
  end

  private

  def service_options(account)
    {
      seed_csv_path: seed_csv_path_for(account),
      keep_emails: ENV.fetch('DEMO_KEEP_USERS', '').split(','),
      import_user_email: ENV['DEMO_IMPORT_USER'].presence,
      health_check: ENV['DEMO_HEALTH_CHECK'].presence&.constantize
    }
  end

  def seed_csv_path_for(account)
    template = ENV['DEMO_SEED_CSV_PATH'].presence
    return unless template

    format(template, tenant: account.name)
  end
end
