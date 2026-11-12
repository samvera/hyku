# frozen_string_literal: true

namespace :hyku do
  desc <<~DESC
    Delete stale guest users in throttled batches. Users are shared across
    tenants, so this runs once. Also runs daily as PruneStaleGuestUsersJob when
    HYKU_SCHEDULE_PRUNE_JOBS is on.

    Options (all via environment variables):

      OLDER_THAN_DAYS      Age cutoff on updated_at. (default: 7)
      BATCH_SIZE           Rows deleted per batch. (default: 5000)
      BATCH_SLEEP_SECONDS  Pause between batches. (default: 1)
      DRY_RUN              Set to "true" to only report how many rows would be
                           deleted. (default: false)
  DESC
  task prune_stale_guest_users: :environment do
    StaleGuestUsersPruner.call(
      older_than_days: ENV.fetch('OLDER_THAN_DAYS', 7).to_i,
      batch_size: ENV.fetch('BATCH_SIZE', 5_000).to_i,
      batch_sleep_seconds: ENV.fetch('BATCH_SLEEP_SECONDS', 1).to_f,
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', false))
    )
  end
end
