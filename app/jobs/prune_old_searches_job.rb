# frozen_string_literal: true

# Daily prune of old anonymous searches. One of these runs per tenant; Account#find_or_schedule_jobs
# registers it when HYKU_SCHEDULE_PRUNE_JOBS is on. Each run is capped by HYKU_PRUNE_MAX_BATCHES.
class PruneOldSearchesJob < ApplicationJob
  queue_as :default

  def perform
    OldSearchesPruner.call(max_batches: PruneJobs.max_batches)
    PruneOldSearchesJob.set(wait_until: Date.tomorrow.midnight + 2.hours).perform_later
  end
end
