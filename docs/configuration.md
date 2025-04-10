# Configuring Hyku

Hyku is primarily configured using environment variables. The default configuration is found in the `.env` file.


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
| REPOSITORY_S3_STORAGE | Whether to turn on S3 or S3 like storage for Valkyrie or not | false | no |
| REPOSITORY_S3_BUCKET | If storing file uploads in S3, what bucket should they be put in | - | no |
| REPOSITORY_S3_REGION | Region code for S3 like storage  | - | no |
| REPOSITORY_S3_ACCESS_KEY | Access key for S3 like storage | - | no |
| REPOSITORY_S3_SECRET_KEY | The secret key for S3 like storage | - | no |
| REPOSITORY_S3_ENDPOINT | Needed for S3 like storage such as Minio or custom S3 endpoints | - | no |
| REPOSITORY_S3_PORT | Only needed for S3 like storage like Minio | - | no |
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



## Single Tenant Mode

Much of the default configuration in Hyku is set up to use multi-tenant mode.  This default mode allows Hyku users to run the equivielent of multiple Hyrax installs on a single set of resources. However, sometimes the subdomain splitting multi-headed complexity is simply not needed.  If this is the case, then single tenant mode is for you.  Single tenant mode will not show the tenant sign up page, or any of the tenant management screens. Instead it shows a single Samvera instance at what ever domain is pointed at the application.

To enable single tenant, set `HYKU_MULTITENANT=false` in your `docker-compose.yml` and `docker-compose.production.yml` configs. After changinig this setting, run `rails db:seed` to prepopulate the single tenant.

In single tenant mode, both the application root (eg. localhost, or hyku.test) and the tenant url single.* (eg. single.hyku.test) will load the tenant. Override the root host by setting HYKU_ROOT_HOST`.

To change from single- to multi-tenant mode, change the multitenancy/enabled flag to true and restart the application. Change the 'single' tenant account cname in the Accounts edit interface to the correct hostname.


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


## Working with Translations

You can log all of the I18n lookups to the Rails logger by setting the I18N_DEBUG environment variable to true. This will add a lot of chatter to the Rails logger (but can be very helpful to zero in on what I18n key you should or could use).

```console
$ I18N_DEBUG=true bin/rails server
```

## S3 Like Storage

You can upload your primary works to S3 in Valkyrie mode by turning on `REPOSITORY_S3_STORAGE` and setting the accompanying bucket and credentials variables. This enables both AWS S3 and other S3 like storage engines such as Minio. As of this writing this only affects Valkyrie resources and only the primary storage. Derivatives, uploads and branding assets all still go to the shared storage directories.
