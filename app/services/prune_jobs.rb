# frozen_string_literal: true

# Settings shared by the prune jobs and rake tasks.
module PruneJobs
  # Bounds one run so a large backlog drains over several days instead of one long job.
  def self.max_batches
    ENV.fetch('HYKU_PRUNE_MAX_BATCHES', 100).to_i
  end

  # Pruner options read from the environment by the rake tasks.
  def self.options_from_env(older_than_days:)
    days = Integer(ENV.fetch('OLDER_THAN_DAYS', older_than_days))
    raise ArgumentError, 'OLDER_THAN_DAYS must be at least 1' unless days.positive?

    {
      older_than_days: days,
      batch_size: ENV.fetch('BATCH_SIZE', 5_000).to_i,
      batch_sleep_seconds: ENV.fetch('BATCH_SLEEP_SECONDS', 1).to_f,
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', false))
    }
  end
end
