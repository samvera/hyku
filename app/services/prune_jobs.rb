# frozen_string_literal: true

# Settings shared by the scheduled prune jobs (PruneOldSearchesJob, PruneStaleGuestUsersJob).
module PruneJobs
  # Off by default: the jobs delete rows, so each deployment opts in.
  def self.enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_SCHEDULE_PRUNE_JOBS', false))
  end

  # Bounds one run so a large backlog drains over several days instead of one long job.
  def self.max_batches
    ENV.fetch('HYKU_PRUNE_MAX_BATCHES', 100).to_i
  end
end
