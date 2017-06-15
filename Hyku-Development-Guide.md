## Testing

Obviously, you must have completed the installation of [Hyrax Prerequisites](https://github.com/projecthydra-labs/hyrax#prerequisites), including PhantomJS, ImageMagick and FITS.  

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

## Production debugging on laptop

Try to apply this config patch in https://gist.github.com/darrenleeweber/2c8b9f4a32e4ca6bcb0a58cf5ac3d97e (disclaimer: works for me).
```
solr_wrapper   -p 8981 -n hydra-production
fcrepo_wrapper -p 8982
DISABLE_REDIS_CLUSTER=true RAILS_ENV=production bundle exec sidekiq

RAILS_ENV=production bin/setup # fix stuff until it works
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails assets:precompile
RAILS_ENV=production RAILS_SERVE_STATIC_FILES=true rails s
```

## See Also

- the [Hyrax Development Guide](https://github.com/samvera-labs/hyrax/wiki/Hyrax-Development-Guide#start-servers-individually-for-development) for more background.