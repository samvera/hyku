# frozen_string_literal: true

class RedisEndpoint < Endpoint
  has_one :account, dependent: nil, foreign_key: :redis_endpoint_id # rubocop:disable Rails/RedundantForeignKey
  store :options, accessors: [:namespace]

  def switch!
    Hyrax.config.redis_namespace = switchable_options[:namespace]
    queue_adapter = Valkyrie::IndexingAdapter.find(:redis_queue)
    return if queue_adapter.nil? || account.nil?
    queue_adapter.index_queue_name = "toindex#{account.tenant}"
    queue_adapter.delete_queue_name = "todelete#{account.tenant}"
  rescue KeyError
    # If Redis queue indexing adapter not found, do nothing
    Rails.logger.warn "Redis queue indexing adapter not found"
  end

  # Reset the Redis namespace back to the default value
  def self.reset!
    Hyrax.config.redis_namespace = ENV.fetch('HYRAX_REDIS_NAMESPACE', 'hyrax')
    queue_adapter = Valkyrie::IndexingAdapter.find(:redis_queue)
    return unless queue_adapter
    queue_adapter.index_queue_name = "toindex"
    queue_adapter.delete_queue_name = "todelete"
  rescue KeyError
    # If Redis queue indexing adapter not found, do nothing
    Rails.logger.warn "Redis queue indexing adapter not found"
  end

  def ping
    redis_instance.ping
  rescue StandardError
    false
  end

  # Remove all the keys in Redis in this namespace, then destroy the record
  def remove!
    switch!
    # redis-namespace v1.10.0 introduced clear https://github.com/resque/redis-namespace/pull/202
    redis_instance.connection.clear
    destroy
  end

  private

  def redis_instance
    Hyrax::RedisEventStore.instance
  end
end
