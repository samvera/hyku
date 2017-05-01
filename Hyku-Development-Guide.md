## Testing

### Prerequisites

- postgresql service is running
  - macOS:
    - `postgres -D ./db/postgres`
  - debian/ubuntu
    - https://help.ubuntu.com/community/PostgreSQL
    - `service postgresql status` or `sudo service postgresql start`

- redis service is running
  - macOS
    - `redis-server /usr/local/etc/redis.conf`
  - debian/ubuntu
    - https://askubuntu.com/questions/868848/how-to-install-redis-on-ubuntu-16-04
    - `service redis status` or `sudo service redis start`

- solr and fedora wrappers

  - The default wrapper configs are for development, but testing will expect solr and fedora on different ports.  Run Solr and Fedora in their own shell windows to isolate their logs.

    ```bash
    bundle exec solr_wrapper   -v --config config/solr_wrapper_test.yml
    bundle exec fcrepo_wrapper -v --config config/fcrepo_wrapper_test.yml
    ```

- phantomjs
  - macOS
    - http://brewformulas.org/phantomj
    - `brew install phantomjs`
  - debian/ubuntu
    - `sudo apt-get install phantomjs`

### Running Specs

```bash
DISABLE_REDIS_CLUSTER=true RAILS_ENV=test bundle exec rails server -b 0.0.0.0
bundle exec rake spec
```

## See Also

- the [Sufia Development Guide](https://github.com/projecthydra/sufia/wiki/Sufia-Development-Guide#start-servers-individually-for-development) for more background.