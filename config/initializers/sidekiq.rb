config = YAML.load(ERB.new(IO.read(Rails.root + 'config' + 'redis.yml')).result)[Rails.env].with_indifferent_access
redis_config = config.merge(thread_safe: true)

Sidekiq.configure_server do |s|
  s.redis = redis_config
end

Sidekiq.configure_client do |s|
  s.redis = redis_config
end
