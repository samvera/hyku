# frozen_string_literal: true

class RedisEndpoint < Endpoint
  store :options, accessors: [:namespace]

  def switch!
    Hyrax.config.redis_namespace = switchable_options[:namespace]
  end

  # Reset the Redis namespace back to the default value
  def self.reset!
    Hyrax.config.redis_namespace = ENV.fetch('HYRAX_REDIS_NAMESPACE', 'hyrax')
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
    redis_instance.clear
    destroy
  end

  private

  def redis_instance
    Hyrax::RedisEventStore.instance
  end
end
