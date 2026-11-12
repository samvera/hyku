# frozen_string_literal: true

# Deletes anonymous Blacklight searches older than a cutoff from the current tenant.
# Searches saved by a user (user_id present) are never touched.
class OldSearchesPruner
  def self.call(**options)
    new(**options).call
  end

  def initialize(older_than_days: 30, batch_size: 5_000, batch_sleep_seconds: 1, max_batches: nil, dry_run: false)
    @older_than_days = older_than_days
    @batch_size = batch_size
    @batch_sleep_seconds = batch_sleep_seconds
    @max_batches = max_batches
    @dry_run = dry_run
  end

  # Returns the number of rows deleted (or that would be, on a dry run).
  def call
    scope = Search.where(user_id: nil).where(created_at: ...@older_than_days.days.ago)
    total = scope.count
    Rails.logger.info("OldSearchesPruner: #{@dry_run ? 'would delete' : 'deleting'} #{total} old anonymous searches")
    return total if @dry_run || total.zero?

    delete_in_batches(scope, total)
  end

  private

  def delete_in_batches(scope, total)
    deleted = 0
    batches = 0
    scope.in_batches(of: @batch_size) do |batch|
      deleted += batch.delete_all
      batches += 1
      Rails.logger.info("OldSearchesPruner: deleted #{deleted}/#{total}")
      break if @max_batches && batches >= @max_batches

      sleep @batch_sleep_seconds
    end
    deleted
  end
end
