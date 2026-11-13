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
    options = PruneJobs.options_from_env(older_than_days: StaleGuestUsersPruner::DEFAULT_OLDER_THAN_DAYS)
    StaleGuestUsersPruner.call(**options)
  end
end
