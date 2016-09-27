config = YAML.load(ERB.new(IO.read(Rails.root + 'config' + 'redis.yml')).result)[Rails.env].with_indifferent_access

redis_conn = proc {
  Redis.new url: "redis://#{config[:host]}:#{config[:port]}/", role: :master, sentinels: [(config[:sentinel] if config[:sentinel] && config[:sentinel][:host])]
}

Sidekiq.configure_server do |s|
  s.redis = ConnectionPool.new(&redis_conn)
end

Sidekiq.configure_client do |s|
  s.redis = ConnectionPool.new(&redis_conn)
end
