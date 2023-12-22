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

This command starts the whole stack in individual containers allowing Rails to be started or stopped independent of the other services.  Once that starts (you'll see the line `Passenger core running in multi-application mode.` or `Listening on tcp://0.0.0.0:3000` to indicate a successful boot), you can view your app in a web browser at either hyku.test or localhost:3000 (see above).  When done `docker-compose stop` shuts down everything.

#### Troubleshooting on Windows
1. Dory is running but you're unable to access hyku.test:
    - Run this in the terminal: `ip addr | grep eth0 | grep inet`
    - Copy the first IP address from the result in your terminal
    - Use the steps under "Change the File Manually" at [this link](https://www.hostinger.co.uk/tutorials/how-to-edit-hosts-file#:~:text=Change%20the%20File%20Manually,-Press%20Start%20and&text=Once%20in%20Notepad%2C%20go%20to,space%2C%20then%20your%20domain%20name) to open your host file
    - At the bottom of the host file add this line: `<your-ip-address> hyku.test`
    - Save (_You may or may not need to restart your server_)
2. When creating a work and adding a file, you get an internal server error due to ownership/permissions issues of the tmp directory:
    - Gain root access to the container (in a slightly hacky way, check_volumes container runs from root): `docker compose run check_volumes bash`
    - Change ownership to app: `chown -R app:app /app/samvera/hyrax-webapp`
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

## Analytics Feature
Hyku currently only supports the configuration of one Google Analytics account for the basic functionality of this feature. Hyku currently only support Google Analytics with the Universal Analytics property for this feature.

Note: Google has announced they will stop processing data using the Universal Analytics property on July 1, 2023  or July 1, 2024 for Analytics 360 properties.

To enable analytics tracking and reporting features within Hyku, please follow the directions below.

### Setup a Google Analytics Account
- Create a Service Account: https://cloud.google.com/iam/docs/creating-managing-service-accounts
  - Note the service account email
  - When making a service account key, make sure the key type is set to p12
  - Note the service account private key secret
- Create an OAuth 2.0 Client ID: https://developers.google.com/identity/protocols/oauth2/web-server#creatingcred
- Create an Analytics account: https://support.google.com/analytics/answer/10269537?hl=en
  - Note Google Universal Analytics ID number
- Add service account email  as User, and grant "View" access: https://support.google.com/analytics/answer/1009702?hl=en#Add&zippy=%2Cin-this-article
- Enable the "Google Analytics API": https://developers.google.com/identity/protocols/oauth2/web-server#enable-apis
- Enable the "IAM Service Account Credentials API": https://developers.google.com/identity/protocols/oauth2/web-server#enable-apis

### Set the Environment Variables
In Hyku there are a few areas to set the environment variables needed for each of your environments development/staging/prodeuction/etc.

- Uncomment the config/analytics.yml file where the below mentioned environment variables will connect to our application.

```yaml
analytics:
  google:
    analytics_id: <%= ENV['GOOGLE_ANALYTICS_ID'] %>
    app_name: <%= ENV['GOOGLE_OAUTH_APP_NAME'] %>
    app_version: <%= ENV['GOOGLE_OAUTH_APP_VERSION'] %>
    privkey_path: <%= ENV['GOOGLE_OAUTH_PRIVATE_KEY_PATH'] %>
    privkey_secret: <%= ENV['GOOGLE_OAUTH_PRIVATE_KEY_SECRET'] %>
    client_email: <%= ENV['GOOGLE_OAUTH_CLIENT_EMAIL'] %>
```

- For local development please see the .env file and see the "Enable Google Analytics" section.

```yaml
##START## Enable Google Analytics
# Uncomment to enable and configure Google Analytics, see README for instructions.
HYRAX_ANALYTICS=true
GOOGLE_ANALYTICS_ID=UA-123456-12
GOOGLE_OAUTH_APP_NAME=hyku-demo
GOOGLE_OAUTH_APP_VERSION=1.0
GOOGLE_OAUTH_PRIVATE_KEY_SECRET=not-a-secret
GOOGLE_OAUTH_PRIVATE_KEY_PATH=prod-cred.p12
GOOGLE_OAUTH_CLIENT_EMAIL=set-me@email.com

# AND comment this out
# HYRAX_ANALYTICS=false
##END## Enable Google Analytics
```

- For deployment to staging/production please update/add the variables and values to the helm values files located in the ops directory (example: staging-deploy.tmpl.yaml).

```yaml
  - name: GOOGLE_ANALYTICS_ID
    value: $GOOGLE_ANALYTICS_ID # Set in GitHub's Environment Secrets
  - name: GOOGLE_OAUTH_APP_NAME
    value: hyku-demo
  - name: GOOGLE_OAUTH_APP_VERSION
    value: '1.0'
  - name: GOOGLE_OAUTH_PRIVATE_KEY_SECRET
    value: $GOOGLE_OAUTH_PRIVATE_KEY_SECRET # Set in GitHub's Environment Secrets
  - name: GOOGLE_OAUTH_PRIVATE_KEY_PATH
    value: prod-cred.p12 # The p12 file is in root and named `prod-cred.p12`
  - name: GOOGLE_OAUTH_PRIVATE_KEY_VALUE
    value: $GOOGLE_OAUTH_PRIVATE_KEY_VALUE # Set in GitHub's Environment Secrets
  - name: GOOGLE_OAUTH_CLIENT_EMAIL
    value: set-me@email.com
  - name: HYRAX_ANALYTICS
    value: 'true'
```

To get the `GOOGLE_OAUTH_PRIVATE_KEY_VALUE` value to set the variable in GitHub's Environment Secrets, you need the path to the p12 file you got from setting up your Google Service Account and run the following in your console locally.

`base64 -i path/to/file.p12 | pbcopy`

Once you run this script the value is on your local computers clipboard. You will need to paste this into GitHubs Environment Secrets or however you/your organization are handling secrets.

## Environment Variables

| Name | Description | Default | Development or Test Only |
| ------------- | ------------- | ------------- | ------------- |
| CHROME_HOSTNAME | specifies the chromium host for feature specs | chrome | yes |
| DB_ADAPTER | which Rails database adapter, mapped in to config/database.yml. Common values are postgresql, mysql2, jdbc, nulldb | postgresql | no |
| DB_HOST | host name for the database | db | no |
| DB_NAME | name of database on database host | hyku | no |
| DB_PASSWORD | password for connecting to database | | no |
| DB_PORT | Port for database connections | 5432 | no |
| DB_TEST_NAME | name of database on database host for tests to run against. Should be different than the development database name or your tests will clobber your dev set up | hyku_test | yes |
| DB_USER | username for the database connection | postgres | no |
| FCREPO_BASE_PATH | Fedora root path | /hykudemo | no
| FCREPO_DEV_BASE_PATH | Fedora root path used for dev instance | /dev | yes
| FCREPO_DEVELOPMENT_PORT | Port used for fedora dev instance | 8984 | yes
| FCREPO_HOST | host name for the fedora repo | fcrepo | no |
| FCREPO_PORT | port for the fedora repo | 8080 | no |
| FCREPO_REST_PATH | Fedora REST endpoint | rest | no
| FCREPO_STAGING_BASE_PATH | Fedora root path used for dev instance | /staging | no
| FCREPO_TEST_BASE_PATH | Fedora root path used for test instance | /test | yes
| FCREPO_TEST_PORT | Test port for the fedora repo  8986 | yes |
| GOOGLE_ANALYTICS_ID | The Google Analytics account id. Disabled if not set | - | no |
| GOOGLE_OAUTH_APP_NAME | The name of the application. | - | no |
| GOOGLE_OAUTH_APP_VERSION | The version of application. | - | no |
| GOOGLE_OAUTH_PRIVATE_KEY_SECRET | The secret provided by Google when you created the key. | - | no |
| GOOGLE_OAUTH_PRIVATE_KEY_PATH | The full path to your p12, key file. | - | no |
| GOOGLE_OAUTH_PRIVATE_KEY_VALUE | The value of the p12 file with base64 encryption, only set on deployment as that is how we get the p12 file on the server (see bin/web & bin/worker files) | - | no
| GOOGLE_OAUTH_CLIENT_EMAIL | OAuth Client email address.  | set-me@email.com | no |
| HYKU_ADMIN_HOST | URL of the admin / proprietor host in a multitenant environment | hyku.test | no |
| HYKU_ADMIN_ONLY_TENANT_CREATION | Restrict signing up a new tenant to the admin | false | no | |
| HYKU_ALLOW_SIGNUP | Can users register themselves on a given Tenant | true  | no |
| HYKU_ASSET_HOST | Host name of the asset server | - | no |
| HYKU_BULKRAX_ENABLED | Is the Bulkrax gem enabled | true | no |
| HYKU_BULKRAX_VALIDATIONS | Unused, pending feature addition by Ubiquity | - | no |
| HYKU_CACHE_API | Use Redis instead of disk for caching | false | no |
| HYKU_CACHE_ROOT | Directory of file cache (if CACHE_API is false) | /app/samvera/file_cache | no |
| HYKU_CONTACT_EMAIL | Email address used for the FROM field when the contact form is submitted | change-me-in-settings@example.com | no |
| HYKU_CONTACT_EMAIL_TO | Email addresses (comma separated) that receive contact form submissions | change-me-in-settings@example.com | no |
| HYKU_DEFAULT_HOST  | The host name pattern each tenant will respond to by default. %{tenant} is substituted for the tenants name. | "%{tenant}.#{admin_host}" | no |
| HYKU_DOI_READER | Does the work new / edit form allow reading in a DOI from Datacite? | false | no |
| HYKU_DOI_WRITER | Does saving or updating a work write to Datacite once the work is approved | false | no |
| HYKU_ELASTIC_JOBS | Use AWS Elastic jobs for background jobs | false | no |
| HYKU_EMAIL_FORMAT | Validate if user emails match a basic email regexp (currently `/@\S*.\S*/`) | false | no |
| HYKU_EMAIL_SUBJECT_PREFIX | String to put in front of system email subjects | - | no |
| HYKU_ENABLE_OAI_METADATA | Not used. Placeholder for upcoming OAI feature. | false | no |
| HYKU_FILE_ACL | Set Unix ACLs on file creation. Set to false if using Azure cloud or another network file system that does not allow setting permissions on files. | true | no |
| HYKU_FILE_SIZE_LIMIT | How big a file do you want to accept in the work upload?  | 5242880 (5 MB) | no |
| HYKU_GEONAMES_USERNAME | Username used for Geonames connections by the application | '' | no |
| HYKU_GOOGLE_SCHOLARLY_WORK_TYPES | List of work types which should be presented to Google Scholar for indexing. Comma separated WorkType list | - | no |
| HYKU_GTM_ID | If set, enable Google Tag manager with this id.  | - | no |
| HYKU_LOCALE_NAME | Not used. Placeholder for upcoming Ubiquity feature | en | no |
| HYKU_MONTHLY_EMAIL_LIST | Not used. Placeholder for upcoming Ubiquity feature | en | no |
| HYKU_MULTITENANT | Set application up for multitenantcy, or use the single tenant version. | false | no |
| HYKU_OAI_ADMIN_EMAIL | OAI endpoint contact address | changeme@example.com | no |
| HYKU_OAI_PREFIX | OAI namespace metadata prefix | oai:hyku | no |
| HYKU_OAI_SAMPLE_IDENTIFIER | OAI example of what an identify might look like | 806bbc5e-8ebe-468c-a188-b7c14fbe34df | no |
| HYKU_ROOT_HOST | What is the very base url that default subdomains should be tacked on to? | hyku.test | no |
| HYKU_S3_BUCKET | If set basic uploads for things like branding images will be sent to S3 | - | no |
| HYKU_SHARED_LOGIN | Not used. Placeholder for upcoming Ubiquity feature | en | no |
| HYKU_SMTP_SETTINGS | String representing a hash of options for tenant specific SMTP defaults. Can be any of `from user_name password address domain port authentication enable_starttls_auto` | - | no |
| HYKU_SOLR_COLLECTION_OPTIONS | Overrides of specific collection options for Solr. | `{async: nil, auto_add_replicas: nil, collection: { config_name: ENV.fetch('SOLR_CONFIGSET_NAME', 'hyku') }, create_node_set: nil, max_shards_per_node: nil, num_shards: 1, replication_factor: nil, router: { name: nil, field: nil }, rule: nil, shards: nil, snitch: nil}` | no |
| HYKU_SSL_CONFIGURED | Force SSL on page loads and IIIF manifest links | false | no |
| HYKU_WEEKLY_EMAIL_LIST | Not used. Placeholder for upcoming Ubiquity feature | en | no |
| HYKU_YEARLY_EMAIL_LIST | Not used. Placeholder for upcoming Ubiquity feature | en | no |
| HYRAX_ACTIVE_JOB_QUEUE | Which Rails background job runner should be used? | sidekiq | no |
| HYRAX_FITS_PATH | Where is fits.sh installed on the system. Will try the PATH if not set. | /app/fits/fits.sh | no |
| HYRAX_REDIS_NAMESPACE | What namespace should the application use by default | hyrax | no |
| I18N_DEBUG | See [Working with Translations] above | false | yes |
| INITIAL_ADMIN_EMAIL | Admin email used by database seeds. | admin@example.com | no |
| INITIAL_ADMIN_PASSWORD | Admin password used by database seeds. Be sure to change in production. | testing123 | no |
| IN_DOCKER | Used specs to know if we are running inside a container or not. Set to true if in K8S regardless of Docker vs ContainerD | false | yes |
| LD_LIBRARY_PATH | Path used for fits | /app/fits/tools/mediainfo/linux | no |
| NEGATIVE_CAPTCHA_SECRET | A secret value you set for the appliations negative_captcha to work. | default-value-change-me | no |
| RAILS_ENV | https://guides.rubyonrails.org/configuring.html#creating-rails-environments | development | no |
| RAILS_LOG_TO_STDOUT | Redirect all logging to stdout | true | no |
| RAILS_MAX_THREADS | Number of threads to use in puma or sidekiq | 5 | no |
| REDIS_HOST | Host location of redis | redis | no |
| REDIS_PASSWORD | Password for redis, optional | - | no |
| REDIS_URL | Optional explicit redis url, build from host/passsword if not specified | redis://:staging@redis:6397/ | no |
| SECRET_KEY_BASE | Used by Rails to secure sessions, should be a 128 character hex | - | no |
| SMTP_ADDRESS | Address of the smtp endpoint for sending email | - | no |
| SMTP_DOMAIN | Domain for sending email | - | no |
| SMTP_PASSWORD | Password for email sending | - | no |
| SMTP_PORT | Port for email sending | - | no |
| SMTP_USER_NAME | Username for the email connection | - | no |
| SOLR_ADMIN_PASSWORD | Solr requires a user/password when accessing the collections API (which we use to create and manage solr collections and aliases) | admin | no |
| SOLR_ADMIN_USER | Solr requires a user/password when accessing the collections API (which we use to create and manage solr collections and aliases) | admin | no |
| SOLR_COLLECTION_NAME | Name of the Solr collection used by non-tenant search. This is required by Hyrax, but is currently unused by Hyku | hydra-development | no |
| SOLR_CONFIGSET_NAME  | Name of the Solr configset to use when creating new Solr collections | hyku | no |
| SOLR_HOST | Host for the Solr connection | solr | no |
| SOLR_PORT | Solr port | 8983 | no |
| SOLR_URL | URL for the Solr connection | http://admin:admin@solr:8983/solr/ | no |
| WEB_CONCURRENCY | Number of processes to run in either puma or sidekiq | 2 | no |

## Development Dependencies

### Postgres

Hyku supports multitenancy using the `apartment` gem. `apartment` works best with a postgres database.

## Importing
### Bulkrax:

Bulkrax is enabled by default and CSV, OAI and XML importers can be used in the admin dashboard or through the command line API.
More info about configuring and using bulkrax can be found [here](https://github.com/samvera-labs/bulkrax/wiki)

### Commandline Importers

Importing from CSV and PURL directly can be done via Bulkrax.

## Compatibility

* Ruby 2.7 is recommended.  Later versions may also work.
* Rails 5.2 is required.

### Product Owner

[orangewolf](https://github.com/orangewolf)

## Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

## Acknowledgments

This software was developed by the Hydra-in-a-Box Project (DPLA, DuraSpace, and Stanford University) under a grant from IMLS.

This software is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://samvera.atlassian.net/wiki/download/attachments/405216084/samvera-fall-TM-220w-transparent.png?version=1&modificationDate=1540440075555&cacheVersion=1&api=v2)
