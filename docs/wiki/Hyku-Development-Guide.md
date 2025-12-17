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
On Debian/Ubunutu, the redis and postgres steps might look like:
```
[sudo] service postgresql status
[sudo] service redis status
```

### Live Carrierwave S3 Bucket
When you are trying to test specific Carrierwave configuration or behavior and want to use an actual S3 bucket:
```bash
SETTINGS__S3__UPLOAD_BUCKET=hyku-carrierwave-test bundle exec rspec
```
The presence of that setting (`Settings.s3.upload_bucket`) triggers `config/initializers/carrierwave_config.rb` to configure Carrierwave to use carrierwave-aws.  You may need other environmental variables (for secret and key) or aws config file to use S3 live in development.  

## Production debugging on laptop

Apply the patch in https://gist.github.com/darrenleeweber/2c8b9f4a32e4ca6bcb0a58cf5ac3d97e (disclaimer: works for me).
```bash
solr_wrapper   -v --config config/solr_wrapper_production.yml
fcrepo_wrapper -v --config config/fcrepo_wrapper_production.yml

export DISABLE_REDIS_CLUSTER=true
RAILS_ENV=production bundle exec sidekiq

RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/setup # fix stuff until it works
RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 rails db:migrate

RAILS_ENV=production rails assets:precompile
RAILS_ENV=production RAILS_SERVE_STATIC_FILES=true rails s
```

## See Also

- the [Hyrax Development Guide](https://github.com/samvera-labs/hyrax/wiki/Hyrax-Development-Guide#start-servers-individually-for-development) for more background.