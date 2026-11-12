# frozen_string_literal: true

namespace :hyku do
  desc <<~DESC
    Delete stale guest users in throttled batches. Users are shared across
    tenants, so this runs once. Uses bulk delete_all: guest users carry no
    dependent bookmarks, searches, trophies or proxy-deposit records.

    Options (all via environment variables):

      OLDER_THAN_DAYS      Age cutoff on updated_at. (default: 7)
      BATCH_SIZE           Rows deleted per batch. (default: 5000)
      BATCH_SLEEP_SECONDS  Pause between batches. (default: 1)
      DRY_RUN              Set to "true" to only report how many rows would be
                           deleted. (default: false)
  DESC
  task prune_stale_guest_users: :environment do
    older_than_days = ENV.fetch('OLDER_THAN_DAYS', 7).to_i
    batch_size = ENV.fetch('BATCH_SIZE', 5_000).to_i
    batch_sleep_seconds = ENV.fetch('BATCH_SLEEP_SECONDS', 1).to_f
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', false))

    scope = User.unscoped.where(guest: true).where(updated_at: ...older_than_days.days.ago)
    total = scope.count
    Rails.logger.info("hyku:prune_stale_guest_users - #{dry_run ? 'would delete' : 'deleting'} #{total} stale guest users")
    next if dry_run

    deleted = 0
    scope.in_batches(of: batch_size) do |batch|
      deleted += batch.delete_all
      Rails.logger.info("hyku:prune_stale_guest_users - deleted #{deleted}/#{total}")
      sleep batch_sleep_seconds
    end
  end
end
