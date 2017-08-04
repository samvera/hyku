class NilRedisEndpoint < NilEndpoint
  def switch!
    Hyrax.config.redis_namespace = 'nil_redis_endpoint'
  end

  def ping
    false
  end
end
