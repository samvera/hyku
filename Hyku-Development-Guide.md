## Testing

The default wrapper configs are for development, but testing will expect solr and fedora on different ports.  You will need at least 7 processes in background or their own windows/tabs to accomplish a successful test run:
```bash
solr_wrapper   -v --config config/solr_wrapper_test.yml
fcrepo_wrapper -v --config config/fcrepo_wrapper_test.yml
postgres -D ./db/postgres
redis-server /usr/local/etc/redis.conf
DISABLE_REDIS_CLUSTER=true bundle exec sidekiq
DISABLE_REDIS_CLUSTER=true RAILS_ENV=test bundle exec rails server -b 0.0.0.0
bundle exec rake spec
```

## See Also

- the [Sufia Development Guide](https://github.com/projecthydra/sufia/wiki/Sufia-Development-Guide#start-servers-individually-for-development) for more background.