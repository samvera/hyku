# Hyku, the Hydra-in-a-Box Repository Application

Code:
[![Build Status](https://circleci.com/gh/samvera/hyku.svg?style=svg)](https://circleci.com/gh/samvera/hyku)
[![Coverage Status](https://coveralls.io/repos/samvera/hyku/badge.svg?branch=master&service=github)](https://coveralls.io/github/samvera/hyku?branch=master)
[![Stories in Ready](https://img.shields.io/waffle/label/samvera/hyku/ready.svg)](https://waffle.io/samvera/hyku)

Docs:
[![Documentation](http://img.shields.io/badge/DOCUMENTATION-wiki-blue.svg)](https://github.com/samvera/hyku/wiki)
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE)

Jump In: [![Slack Status](http://slack.samvera.org/badge.svg)](http://slack.samvera.org/)

----
## Table of Contents

  * [Running the stack](#running-the-stack)
    * [For development](#for-development)
    * [For testing](#for-testing)
    * [On AWS](#on-aws)
    * [With Docker](#with-docker)
    * [With Vagrant](#with-vagrant)
    * [With Kubernetes](#with-kubernetes)
  * [Single Tenant Mode](#single-tenancy)
  * [Switching accounts](#switching-accounts)
  * [Environment Variables](#environment-variables)
  * [Development dependencies](#development-dependencies)
    * [Postgres](#postgres)
  * [Importing](#importing)
    * [Enable Bulkrax](#enable-bulkrax)
    * [from CSV](#from-csv)
    * [from purl](#from-purl)
  * [Compatibility](#compatibility)
  * [Product Owner](#product-owner)
  * [Help](#help)
  * [Acknowledgments](#acknowledgments)

----

## Running the stack

### For development / testing with Docker

#### Dory

On OS X or Linux we recommend running [Dory](https://github.com/FreedomBen/dory). It acts as a proxy allowing you to access domains locally such as hyku.test or tenant.hyku.test, making multitenant development more straightforward and prevents the need to bind ports locally. Be sure to [adjust your ~/.dory.yml file to support the .test tld](https://github.com/FreedomBen/dory#config-file).  You can still run in development via docker with out Dory. To do so, copy `docker-compose.override-nodory.yml` to `docker-compose.override.yml` before starting doing docker-compose up.  You can then see the application t the loopback domain 'lvh.me:3000'.

```bash
gem install dory
dory up
```

#### Basic steps

```bash
docker-compose up web
```

This command starts the whole stack in individual containers allowing Rails to be started or stopped independent of the other services.  Once that starts (you'll see the line `Passenger core running in multi-application mode.` to indicate a successful boot), you can view your app in a web browser with at either hyku.test or localhost:3000 (see above).  When done `docker-compose stop` shuts down everything.

#### Tests in Docker

The full spec suite can be run in docker locally. There are several ways to do this, but one way is to run the following:

```bash
docker-compose exec web rake
```

### With out Docker

Please note that this is unused by most contributors at this point and will likely become unsupported in a future release of Hyku unless someone in the community steps up to maintain it.

#### For development

```bash
solr_wrapper
fcrepo_wrapper
postgres -D ./db/postgres
redis-server /usr/local/etc/redis.conf
bin/setup
DISABLE_REDIS_CLUSTER=true bundle exec sidekiq
DISABLE_REDIS_CLUSTER=true bundle exec rails server -b 0.0.0.0
```
#### For testing

See the [Hyku Development Guide](https://github.com/samvera/hyku/wiki/Hyku-Development-Guide) for how to run tests.

### Working with Translations

You can log all of the I18n lookups to the Rails logger by setting the I18N_DEBUG environment variable to true. This will add a lot of chatter to the Rails logger (but can be very helpful to zero in on what I18n key you should or could use).

```console
$ I18N_DEBUG=true bin/rails server
```

### On AWS

AWS CloudFormation templates for the Hyku stack are available in a separate repository:

https://github.com/hybox/aws

### With Docker

We distribute two `docker-compose.yml` configuration files.  The first is set up for development / running the specs. The other, `docker-compose.production.yml` is for running the Hyku stack in a production setting. . Once you have [docker](https://docker.com) installed and running, launch the stack using e.g.:

```bash
docker-compose up -d web
```

Note: You may need to add your user to the "docker" group.

```sudo gpasswd -a $USER docker
newgrp docker
```

### With Vagrant

The [samvera-vagrant project](https://github.com/samvera-labs/samvera-vagrant) provides another simple way to get started "kicking the tires" of Hyku (and [Hyrax](http://hyr.ax/)), making it easy and quick to spin up Hyku. (Note that this is not for production or production-like installations.) It requires [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/).

### With Kubernetes

Hyku relies on the helm charts provided by Hyrax. See [Deployment Info](https://github.com/samvera/hyrax/blob/main/CONTAINERS.md#deploying-to-production) for more information. We also provide a basic helm [deployment script](bin/helm_deploy). Hyku currently needs some additional volumes and ENV vars over the base Hyrax. See (ops/review-deploy.tmpl.yaml) for an example of what that might look like.

## Single Tenant Mode

Much of the default configuration in Hyku is set up to use multi-tenant mode.  This default mode allows Hyku users to run the equivielent of multiple Hyrax installs on a single set of resources. However, sometimes the subdomain splitting multi-headed complexity is simply not needed.  If this is the case, then single tenant mode is for you.  Single tenant mode will not show the tenant sign up page, or any of the tenant management screens. Instead it shows a single Samvera instance at what ever domain is pointed at the application.

To enable single tenant, set `HYKU_MULTITENANT=false` in your `docker-compose.yml` and `docker-compose.production.yml` configs. After changinig this setting, run `rails db:seed` to prepopulate the single tenant.

In single tenant mode, both the application root (eg. localhost, or hyku.test) and the tenant url single.* (eg. single.hyku.test) will load the tenant. Override the root host by setting HYKU_ROOT_HOST`.

To change from single- to multi-tenant mode, change the multitenancy/enabled flag to true and restart the application. Change the 'single' tenant account cname in the Accounts edit interface to the correct hostname.

## Switching accounts
There are three recommend ways to switch your current session from one account to another by using:
```ruby
switch!(Account.first)
# or
switch!('my.site.com')
# or
switch!('myaccount')
```

## Environment Variables

| First Header  | Second Header |
| ------------- | ------------- |
| Content Cell  | Content Cell  |
| Content Cell  | Content Cell  |

| Name | Description | Default | Development or Test Only |
| ------------- | ------------- | ------------- | ------------- |
| CHROME_HOSTNAME | specifies the chromium host for feature specs | chrome | yes |
| DB_ADAPTER | which Rails database adapter, mapped in to config/database.yml. Common values are postgresql, mysql2, jdbc, nulldb | postgresql | no |
| DB_HOST | host name for the database | db | no |
| DB_NAME | name of database on database host | hyku | no |
| DB_PASSWORD | password for connecting to database | | no |
| DB_TEST_NAME | name of database on database host for tests to run against. Should be different than the development database name or your tests will clobber your dev set up | hyku_test | yes |
| DB_USER | username for the database connection | postgres | no |
| DB_PORT | Port for database connections | 5432 | no |
| FCREPO_DEVELOPMENT_PORT | Port used for fedora dev instance, only if FCREPO_URL is blank | 8984 | yes
| FCREPO_HOST | host name for the fedora repo | ? | no |
| FCREPO_PORT | port for the fedora repo | 8080 | no |
| FCREPO_TEST_PORT | Test port for the fedora repo, only if FCREPO_URL is blank | 8986 | yes |
| FCREPO_URL | URL of the fedora repo, including port and prefix, but not repo name. | http://fcrepo:8080/rest | no |
| HYKU_ADMIN_HOST | URL of the admin / propritor host in a multitenant environment | hyku.test | no |
| HYKU_ADMIN_ONLY_TENANT_CREATION | Restrict signing up a new tenant to the admin | false | no | |
| HYKU_ALLOW_SIGNUP | Can users register themselves on a given Tenant | true  | no |
| HYKU_ASSET_HOST | Host name of the asset server | - | no |
| HYKU_BULKRAX_ENABLED | Is the Bulkrax gem enabled | false | no |
| HYKU_BULKRAX_VALIDATIONS | Unused, pending feature addition by Ubiquity | - | no |
| HYKU_CACHE_API | Use Redis instead of disk for caching | false | no |
| HYKU_CACHE_ROOT | Directory of file cache (if CACHE_API is false) | /app/samvera/file_cache | no |
| HYKU_CONTACT_EMAIL | Email address used for the FROM field when the contact form is submitted | change-me-in-settings@example.com | no |
| HYKU_CONTACT_EMAIL_TO | Email addresses (comma seperated) that receive contact form submissions | change-me-in-settings@example.com | no |
| HYKU_DEFAULT_HOST  | The host name pattern each tenant will respond to by default. %{tenant} is substituted for the tenants name. | "%{tenant}.#{admin_host}" | no |
| HYKU_DOI_READER | Does the work new / edit form allow reading in a DOI from Datacite? | false | no |
| HYKU_DOI_WRITER | Does saving or updating a work write to Datacite once the work is approved | false | no |
| HYKU_ELASTIC_JOBS | Use AWS Elastic jobs for background jobs | false | no |
| HYKU_EMAIL_FORMAT | Validate if user emails match a basic email regexp (currently `/@\S*.\S*/`) | false | no |
| HYKU_EMAIL_SUBJECT_PREFIX | String to put in front of system email subjects | - | no |
| HYKU_ENABLE_OAI_METADATA | Not used. Placeholder for upcoming OAI feature. | false | no |
| HYKU_FILE_ACL | Set Unix ACLs on file creation. Set to false if using Azure cloud or another network file ssytem that does not allow setting permissions on files. | true | no |
| HYKU_FILE_SIZE_LIMIT | How big a file do you want to accept in the work upload?  | 5242880 (5 MB) | no |
| HYKU_GEONAMES_USERNAME | Username used for Geonames connections by the application | '' | no |
| HYKU_GOOGLE_ANALYTICS_ID | Id for the applications Google Analytics account. Disabled if not set | - | no |
| HYKU_GOOGLE_SCHOLARLY_WORK_TYPES | List of work types which should be presented to Google Scholar for indexing. Comman seperated WorkType list | - | no |
| HYKU_GTM_ID | If set, enable Google Tag manager with this id.  | - | no |
| HYKU_LOCALE_NAME | Not used. Placeholder for upcoming Ubiquity feature | en | no |
| HYKU_MONTHLY_EMAIL_LIST | Not used. Placeholder for upcoming Ubiquity feature | en | no |
| HYKU_MULTITENANT | Set application up for multitenantcy, or use the single tenant version. | false | no |
| HYKU_OAI_ADMIN_EMAIL | OAI endpoint contact address | changeme@example.com | no |
| HYKU_OAI_PREFIX | OAI namespace metadata prefix | oai:hyku | no |
| HYKU_OAI_SAMPLE_IDENTIFIER | OAI example of what an identify might look like | 806bbc5e-8ebe-468c-a188-b7c14fbe34df | no |
| HYKU_ROOT_HOST | ? | ? | ? |
| HYKU_S3_BUCKET | ? | ? | ? |
| HYKU_ROOT_HOST | ? | ? | ? |
| HYKU_SETTING_NAME | ? | ? | ? |
| HYKU_SHARED_LOGIN | ? | ? | ? |
| HYKU_SMTP_SETTINGS | ? | ? | ? |
| HYKU_SOLR_COLLECTION_OPTIONS | ? | ? | ? |
| HYKU_SSL_CONFIGURED | ? | ? | ? |
| HYKU_WEEKLY_EMAIL_LIST | Not used. Placeholder for upcoming Ubiquity feature | en | no |
| HYKU_YEARLY_EMAIL_LIST | Not used. Placeholder for upcoming Ubiquity feature | en | no |
| HYRAX_ACTIVE_JOB_QUEUE | Which Rails background job runner should be used? | sidekiq | no |
| HYRAX_FITS_PATH | ? | ? | ? |
| HYRAX_REDIS_NAMESPACE | ? | ? | ? |
| I18N_DEBUG | ? | ? | ? |
| INITIAL_ADMIN_EMAIL | Admin email used by database seeds. | admin@example.com | no |
| INITIAL_ADMIN_PASSWORD | Admin password used by database seeds. Be sure to change in production. | testing123 | no |
| IN_DOCKER | Used specs to know if we are running inside a container or not. Set to true if in K8S regardless of Docker vs Containerd | false | yes |
| INITIAL_ADMIN_PASSWORD | ? | ? | ? |
| LD_LIBRARY_PATH | ? | ? | ? |
| PASSENGER_APP_ENV | ? | ? | ? |
| RAILS_ENV | ? | ? | ? |
| RAILS_LOG_TO_STDOUT | ? | ? | ? |
| RAILS_LOG_TO_STDOUT | ? | ? | ? |
| RAILS_MAX_THREADS | ? | ? | ? |
| REDIS_HOST | ? | ? | ? |
| REDIS_PASSWORD | ? | ? | ? |
| REDIS_HOST | ? | ? | ? |
| REDIS_URL SECRET_KEY_BASE  | ? | ? | ? |
| SECRET_KEY_BASE | ? | ? | ? |
| SMTP_ADDRESS | ? | ? | ? |
| SMTP_DOMAIN | ? | ? | ? |
| SMTP_PASSWORD | ? | ? | ? |
| SMTP_PORT | ? | ? | ? |
| SMTP_USER_NAME | username for the STMP connection |
| SOLR_ADMIN_PASSWORD | ? | ? | ? |
| SOLR_ADMIN_USER | ? | ? | ? |
| SOLR_COLLECTION_NAME | ? | ? | ? |
| SOLR_CONFIGSET_NAME | ? | ? | ? |
| SOLR_PORT  | ? | ? | ? |
| SOLR_CONFIGSET_NAME  | ? | ? | ? |
| SOLR_HOST | Host for the Solr connection |
| SOLR_URL | URL for the Solr connection |
| WEB_CONCURRENCY |

HYKU_ROOT_HOST
HYKU_ROOT_HOST=hyku.test
HYKU_S3_BUCKET, type: 'string', private: true
HYKU_SETTING_NAME
HYKU_SHARED_LOGIN, type: 'boolean', disabled: true
HYKU_SMTP_SETTINGS, type: 'hash', private: true, default: {}
HYKU_SOLR_COLLECTION_OPTIONS, type: 'hash', default: solr_collection_options
HYKU_SSL_CONFIGURED, type: 'boolean', default: false, private: true
HYKU_WEEKLY_EMAIL_LIST, type: 'array', disabled: true
HYKU_YEARLY_EMAIL_LIST, type: 'array', disabled: true
HYRAX_ACTIVE_JOB_QUEUE
HYRAX_ACTIVE_JOB_QUEUE=sidekiq
HYRAX_FITS_PATH=/app/fits/fits.sh
HYRAX_REDIS_NAMESPACE
I18N_DEBUG
INITIAL_ADMIN_EMAIL
INITIAL_ADMIN_EMAIL=admin@example.com
INITIAL_ADMIN_PASSWORD
INITIAL_ADMIN_PASSWORD=testing123
IN_DOCKER=true
LD_LIBRARY_PATH=/opt/fits/tools/mediainfo/linux
PASSENGER_APP_ENV=development
RAILS_ENV - development
RAILS_LOG_TO_STDOUT
RAILS_LOG_TO_STDOUT=true
RAILS_MAX_THREADS - 5
REDIS_HOST - localhost
REDIS_HOST=redis
REDIS_PASSWORD - 6397
REDIS_URL
SECRET_KEY_BASE
SECRET_KEY_BASE=asdf
SMTP_ADDRESS
SMTP_DOMAIN
SMTP_PASSWORD
SMTP_PORT
SMTP_USER_NAME
SOLR_ADMIN_PASSWORD=admin
SOLR_ADMIN_USER - admin
SOLR_ADMIN_USER=admin
SOLR_COLLECTION_NAME=hydra-development
SOLR_CONFIGSET_NAME - hyku
SOLR_CONFIGSET_NAME=hyku
SOLR_HOST=solr
SOLR_PORT=8983
SOLR_URL
SOLR_URL=http://admin:admin@solr:8983/solr/
WEB_CONCURRENCY - 5


## Development Dependencies

### Postgres

Hyku supports multitenancy using the `apartment` gem. `apartment` works best with a postgres database.

## Importing
### Enable Bulkrax:

- Set bulkrax -> enabled to true in the [config/settings.yml](config/settings.yml) and [.env](.env) files
- Add `  require bulkrax/application` to app/assets/javascripts/application.js and app/assets/stylesheets/application.css files.

(in a `docker-compose exec web bash` if you're doing docker otherwise in your terminal)
```bash
bundle exec rails db:migrate
```

### from CSV:

```bash
./bin/import_from_csv localhost spec/fixtures/csv/gse_metadata.csv ../hyku-objects
```

### from purl:

```bash
./bin/import_from_purl ../hyku-objects bc390xk2647 bc402fk6835 bc483gc9313
```

## Compatibility

* Ruby 2.4 or the latest 2.3 version is recommended.  Later versions may also work.
* Rails 5 is required. We recommend the latest Rails 5.1 release.

### Product Owner

[orangewolf](https://github.com/orangewolf)

## Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

## Acknowledgments

This software was developed by the Hydra-in-a-Box Project (DPLA, DuraSpace, and Stanford University) under a grant from IMLS.

This software is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://samvera.atlassian.net/wiki/download/attachments/405216084/samvera-fall-TM-220w-transparent.png?version=1&modificationDate=1540440075555&cacheVersion=1&api=v2)
