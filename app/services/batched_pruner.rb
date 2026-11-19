# frozen_string_literal: true

# Deletes rows matching a subclass-defined scope in throttled batches. Subclasses set
# DEFAULT_OLDER_THAN_DAYS and implement #scope (using #cutoff) and #description.
class BatchedPruner
  def self.call(**options)
    new(**options).call
  end

  def initialize(older_than_days: self.class::DEFAULT_OLDER_THAN_DAYS, batch_size: 5_000, batch_sleep_seconds: 1,
                 max_batches: nil, dry_run: false)
    @older_than_days = older_than_days
    @batch_size = batch_size
    @batch_sleep_seconds = batch_sleep_seconds
    @max_batches = max_batches
    @dry_run = dry_run
  end

  # Returns the number of rows deleted (or that would be, on a dry run).
  def call
    total = scope.count
    Rails.logger.info("#{self.class.name}: #{@dry_run ? 'would delete' : 'deleting'} #{total} #{description}")
    return total if @dry_run || total.zero?

    delete_in_batches(total)
  end

  private

  def cutoff
    @older_than_days.days.ago
  end

  def delete_in_batches(total)
    deleted = 0
    batches = 0
    scope.in_batches(of: @batch_size) do |batch|
      deleted += batch.delete_all
      batches += 1
      Rails.logger.info("#{self.class.name}: deleted #{deleted}/#{total}")
      break if @max_batches && batches >= @max_batches

      sleep @batch_sleep_seconds
    end
    deleted
  end
end
