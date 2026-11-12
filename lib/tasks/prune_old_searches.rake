# frozen_string_literal: true

namespace :hyku do
  desc <<~DESC
    Delete old anonymous (unsaved) Blacklight searches across every tenant, in
    throttled batches. Searches saved by a user (user_id present) are never touched.

    A tenant that fails is logged and skipped; the task exits non-zero at the
    end listing them.

    Options (all via environment variables):

      OLDER_THAN_DAYS      Age cutoff on created_at. (default: 30)
      BATCH_SIZE           Rows deleted per batch. (default: 5000)
      BATCH_SLEEP_SECONDS  Pause between batches. (default: 1)
      DRY_RUN              Set to "true" to only report how many rows would be
                           deleted. (default: false)
  DESC
  task prune_old_searches: :environment do
    older_than_days = ENV.fetch('OLDER_THAN_DAYS', 30).to_i
    batch_size = ENV.fetch('BATCH_SIZE', 5_000).to_i
    batch_sleep_seconds = ENV.fetch('BATCH_SLEEP_SECONDS', 1).to_f
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', false))
    cutoff = older_than_days.days.ago
    failed = []

    Account.find_each do |account|
      Apartment::Tenant.switch(account.tenant) do
        scope = Search.where(user_id: nil).where(created_at: ...cutoff)
        total = scope.count
        next if total.zero?

        Rails.logger.info("hyku:prune_old_searches - #{account.cname}: #{dry_run ? 'would delete' : 'deleting'} #{total} old anonymous searches")
        next if dry_run

        deleted = 0
        scope.in_batches(of: batch_size) do |batch|
          deleted += batch.delete_all
          Rails.logger.info("hyku:prune_old_searches - #{account.cname}: deleted #{deleted}/#{total}")
          sleep batch_sleep_seconds
        end
      end
    rescue StandardError => e
      failed << account.cname
      Rails.logger.error("hyku:prune_old_searches - #{account.cname} failed: #{e.class}: #{e.message}")
    end

    abort("hyku:prune_old_searches - failed for: #{failed.join(', ')}") if failed.any?
  end
end
