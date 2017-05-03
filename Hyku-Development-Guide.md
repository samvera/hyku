## Testing

Obviously, you must have completed the installation prerequisites.  

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

#### Debian/Ubuntu
On Debian/Ubunutu, the redis and postgress steps might look like:
```
[sudo] service postgresql status
[sudo] service redis status
```
## See Also

- the [Sufia Development Guide](https://github.com/projecthydra/sufia/wiki/Sufia-Development-Guide#start-servers-individually-for-development) for more background.