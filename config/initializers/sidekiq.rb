config = YAML.load(ERB.new(IO.read(Rails.root + 'config' + 'redis.yml')).result)[Rails.env].with_indifferent_access
redis_config = config.merge(thread_safe: true)

Sidekiq.configure_server do |s|
  s.redis = redis_config

  schedule_file = "config/schedule.yml"
  if File.exists?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end

end

Sidekiq.configure_client do |s|
  s.redis = redis_config
end
