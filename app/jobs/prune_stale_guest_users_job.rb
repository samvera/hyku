# frozen_string_literal: true

# Users are shared across tenants, so this is not a per-tenant job; TenantMaintenanceJob enqueues it
# daily when HYKU_SCHEDULE_PRUNE_JOBS is on. Each run is capped by HYKU_PRUNE_MAX_BATCHES.
class PruneStaleGuestUsersJob < ApplicationJob
  non_tenant_job

  def perform
    StaleGuestUsersPruner.call(max_batches: PruneJobs.max_batches)
  end
end
