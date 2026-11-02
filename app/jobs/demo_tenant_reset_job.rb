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
#   DEMO_RESET_TIME     local time of the nightly reset as "HH:MM", optionally
#                       followed by a time zone name, e.g.
#                       "03:00 America/Los_Angeles" (optional; defaults to
#                       midnight application time, UTC unless configured)
class DemoTenantResetJob < ApplicationJob
  RESET_TIME_FORMAT = /\A(?<hour>[01]?\d|2[0-3]):(?<minute>[0-5]\d)(?:\s+(?<zone>.+))?\z/

  # Without DEMO_RESET_TIME the first run stays immediate, as it was before
  # the setting existed.
  def self.schedule_first_run
    reset_time ? set(wait_until: next_run_at).perform_later : perform_later
  end

  def self.next_run_at(now = Time.current)
    hour, minute, zone = reset_time
    return Date.tomorrow.midnight unless zone

    today = now.in_time_zone(zone).to_date
    run_at = zone.local(today.year, today.month, today.day, hour, minute)
    return run_at if run_at > now

    tomorrow = today.tomorrow
    zone.local(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute)
  end

  # Falls back to midnight with a warning rather than raising: raising after
  # a successful reset would make retry_on run the whole reset again.
  def self.reset_time
    value = ENV['DEMO_RESET_TIME'].presence
    return unless value

    match = RESET_TIME_FORMAT.match(value.strip)
    zone = match && (match[:zone] ? ActiveSupport::TimeZone[match[:zone]] : Time.zone)
    return [match[:hour].to_i, match[:minute].to_i, zone] if zone

    Rails.logger.warn("[DemoTenantReset] ignoring invalid DEMO_RESET_TIME=#{value.inspect}; using midnight")
    nil
  end

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

    DemoTenantResetService.new(account:, **service_options).reset!
    self.class.set(wait_until: self.class.next_run_at).perform_later
  end

  private

  def service_options
    {
      seed_csv_path: ENV['DEMO_SEED_CSV_PATH'].presence,
      keep_emails: ENV.fetch('DEMO_KEEP_USERS', '').split(','),
      import_user_email: ENV['DEMO_IMPORT_USER'].presence,
      health_check: ENV['DEMO_HEALTH_CHECK'].presence&.constantize
    }
  end
end
