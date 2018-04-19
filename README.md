[![Build Status](https://travis-ci.org/samvera-labs/hyku.svg)](https://travis-ci.org/samvera-labs/hyku)
[![Coverage Status](https://coveralls.io/repos/samvera-labs/hyku/badge.svg?branch=master&service=github)](https://coveralls.io/github/samvera-labs/hyku?branch=master)
[![Stories in Ready](https://img.shields.io/waffle/label/samvera-labs/hyku/ready.svg)](https://waffle.io/samvera-labs/hyku)

# Hyku, the Hydra-in-a-Box Repository Application

Product Owner: Hydra-in-a-Box Project (DPLA, DuraSpace, and Stanford University)

## Running the stack

### For development

```bash
solr_wrapper
fcrepo_wrapper
postgres -D ./db/postgres
redis-server /usr/local/etc/redis.conf
bin/setup
DISABLE_REDIS_CLUSTER=true bundle exec sidekiq
DISABLE_REDIS_CLUSTER=true bundle exec rails server -b 0.0.0.0
```
### For testing

See the [Hyku Development Guide](https://github.com/samvera-labs/hyku/wiki/Hyku-Development-Guide) for how to run tests.

### Working with Translations

You can log all of the I18n lookups to the Rails logger by setting the I18N_DEBUG environment variable to true. This will add a lot of chatter to the Rails logger (but can be very helpful to zero in on what I18n key you should or could use).

```console
$ I18N_DEBUG=true bin/rails server
```

### On AWS

AWS CloudFormation templates for the Hyku stack are available in a separate repository:

https://github.com/hybox/aws

### With Docker

We distribute a `docker-compose.yml` configuration for running the Hyku stack and application using docker. Once you have [docker](https://docker.com) installed and running, launch the stack using e.g.:

```bash
docker-compose up -d
```

### With Vagrant

The [samvera-vagrant project](https://github.com/samvera-labs/samvera-vagrant) provides another simple way to get started "kicking the tires" of Hyku (and [Hyrax](http://hyr.ax/)), making it easy and quick to spin up Hyku. (Note that this is not for production or production-like installations.) It requires [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/).

## Switching accounts

The recommend way to switch your current session from one account to another is by doing:

```ruby
AccountElevator.switch!('repo.example.com')
```

## Development Dependencies

### Postgres

Hydra-in-a-Box supports multitenancy using the `apartment` gem. `apartment` works best with a postgres database.

## Importing
### from CSV:

```bash
./bin/import_from_csv localhost spec/fixtures/csv/gse_metadata.csv ../hyku-objects
```

### from purl:

```bash
./bin/import_from_purl ../hyku-objects bc390xk2647 bc402fk6835 bc483gc9313
```
