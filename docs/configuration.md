# Configuring Hyku

Hyku is primarily configured using environment variables. The default configuration is found in the `.env` file.

## Environment Variables

| Name                             | Description                                                                                                                                                              | Default                                                                                                                                                                                                                                                                       | Development or Test Only |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| APP_NAME                         | uniquely identify the endpoint for tenant administration - e.g. `https://admin-hyku.example.org` (production) or `https://admin-hyku.localhost.direct` (development)     | hyku                                                                                                                                                                                                                                                                          | no                       |
| CHROME_HOSTNAME                  | specifies the chromium host for feature specs                                                                                                                            | chrome                                                                                                                                                                                                                                                                        | yes                      |
| DB_ADAPTER                       | which Rails database adapter, mapped in to config/database.yml. Common values are postgresql, mysql2, jdbc, nulldb                                                       | postgresql                                                                                                                                                                                                                                                                    | no                       |
| DB_HOST                          | host name for the database                                                                                                                                               | db                                                                                                                                                                                                                                                                            | no                       |
| DB_NAME                          | name of database on database host                                                                                                                                        | hyku                                                                                                                                                                                                                                                                          | no                       |
| DB_PASSWORD                      | password for connecting to database                                                                                                                                      |                                                                                                                                                                                                                                                                               | no                       |
| DB_PORT                          | Port for database connections                                                                                                                                            | 5432                                                                                                                                                                                                                                                                          | no                       |
| DB_TEST_NAME                     | name of database on database host for tests to run against. Should be different than the development database name or your tests will clobber your dev set up            | hyku_test                                                                                                                                                                                                                                                                     | yes                      |
| DB_USER                          | username for the database connection                                                                                                                                     | postgres                                                                                                                                                                                                                                                                      | no                       |
| FCREPO_BASE_PATH                 | Fedora root path                                                                                                                                                         | /hykudemo                                                                                                                                                                                                                                                                     | no                       |
| FCREPO_DEV_BASE_PATH             | Fedora root path used for dev instance                                                                                                                                   | /dev                                                                                                                                                                                                                                                                          | yes                      |
| FCREPO_DEVELOPMENT_PORT          | Port used for fedora dev instance                                                                                                                                        | 8984                                                                                                                                                                                                                                                                          | yes                      |
| FCREPO_HOST                      | host name for the fedora repo                                                                                                                                            | fcrepo                                                                                                                                                                                                                                                                        | no                       |
| FCREPO_PORT                      | port for the fedora repo                                                                                                                                                 | 8080                                                                                                                                                                                                                                                                          | no                       |
| FCREPO_REST_PATH                 | Fedora REST endpoint                                                                                                                                                     | rest                                                                                                                                                                                                                                                                          | no                       |
| FCREPO_STAGING_BASE_PATH         | Fedora root path used for dev instance                                                                                                                                   | /staging                                                                                                                                                                                                                                                                      | no                       |
| FCREPO_TEST_BASE_PATH            | Fedora root path used for test instance                                                                                                                                  | /test                                                                                                                                                                                                                                                                         | yes                      |
| FCREPO_TEST_PORT                 | Test port for the fedora repo 8986                                                                                                                                       | yes                                                                                                                                                                                                                                                                           |
| GOOGLE_ANALYTICS_ID              | The Google Analytics account id. Disabled if not set                                                                                                                     | -                                                                                                                                                                                                                                                                             | no                       |
| GOOGLE_OAUTH_APP_NAME            | The name of the application.                                                                                                                                             | -                                                                                                                                                                                                                                                                             | no                       |
| GOOGLE_OAUTH_APP_VERSION         | The version of application.                                                                                                                                              | -                                                                                                                                                                                                                                                                             | no                       |
| GOOGLE_OAUTH_PRIVATE_KEY_SECRET  | The secret provided by Google when you created the key.                                                                                                                  | -                                                                                                                                                                                                                                                                             | no                       |
| GOOGLE_OAUTH_PRIVATE_KEY_PATH    | The full path to your p12, key file.                                                                                                                                     | -                                                                                                                                                                                                                                                                             | no                       |
| GOOGLE_OAUTH_PRIVATE_KEY_VALUE   | The value of the p12 file with base64 encryption, only set on deployment as that is how we get the p12 file on the server (see bin/web & bin/worker files)               | -                                                                                                                                                                                                                                                                             | no                       |
| GOOGLE_OAUTH_CLIENT_EMAIL        | OAuth Client email address.                                                                                                                                              | set-me@email.com                                                                                                                                                                                                                                                              | no                       |
| HYKU_ADMIN_HOST                  | URL of the admin / proprietor host in a multitenant environment                                                                                                          | hyku.test                                                                                                                                                                                                                                                                     | no                       |
| HYKU_ADMIN_ONLY_TENANT_CREATION  | Restrict signing up a new tenant to the admin                                                                                                                            | false                                                                                                                                                                                                                                                                         | no                       |
| HYKU_ALLOW_SIGNUP                | Can users register themselves on a given Tenant                                                                                                                          | true                                                                                                                                                                                                                                                                          | no                       |
| HYKU_ASSET_HOST                  | Host name of the asset server                                                                                                                                            | -                                                                                                                                                                                                                                                                             | no                       |
| HYKU_BULKRAX_ENABLED             | Is the Bulkrax gem enabled                                                                                                                                               | true                                                                                                                                                                                                                                                                          | no                       |
| HYKU_BULKRAX_VALIDATIONS         | Unused, pending feature addition by Ubiquity                                                                                                                             | -                                                                                                                                                                                                                                                                             | no                       |
| HYKU_CACHE_API                   | Use Redis instead of disk for caching                                                                                                                                    | false                                                                                                                                                                                                                                                                         | no                       |
| HYKU_CACHE_ROOT                  | Directory of file cache (if CACHE_API is false)                                                                                                                          | /app/samvera/file_cache                                                                                                                                                                                                                                                       | no                       |
| HYKU_CONTACT_EMAIL               | Email address used for the FROM field when the contact form is submitted                                                                                                 | change-me-in-settings@example.com                                                                                                                                                                                                                                             | no                       |
| HYKU_CONTACT_EMAIL_TO            | Email addresses (comma separated) that receive contact form submissions                                                                                                  | change-me-in-settings@example.com                                                                                                                                                                                                                                             | no                       |
| HYKU_DEFAULT_HOST                | The host name pattern each tenant will respond to by default. %{tenant} is substituted for the tenants name.                                                             | "%{tenant}.#{admin_host}"                                                                                                                                                                                                                                                     | no                       |
| HYKU_DOI_READER                  | Does the work new / edit form allow reading in a DOI from Datacite?                                                                                                      | false                                                                                                                                                                                                                                                                         | no                       |
| HYKU_DOI_WRITER                  | Does saving or updating a work write to Datacite once the work is approved                                                                                               | false                                                                                                                                                                                                                                                                         | no                       |
| HYKU_ELASTIC_JOBS                | Use AWS Elastic jobs for background jobs                                                                                                                                 | false                                                                                                                                                                                                                                                                         | no                       |
| HYKU_EMAIL_FORMAT                | Validate if user emails match a basic email regexp (currently `/@\S*.\S*/`)                                                                                              | false                                                                                                                                                                                                                                                                         | no                       |
| HYKU_EMAIL_SUBJECT_PREFIX        | String to put in front of system email subjects                                                                                                                          | -                                                                                                                                                                                                                                                                             | no                       |
| HYKU_ENABLE_OAI_METADATA         | Not used. Placeholder for upcoming OAI feature.                                                                                                                          | false                                                                                                                                                                                                                                                                         | no                       |
| HYKU_FILE_ACL                    | Set Unix ACLs on file creation. Set to false if using Azure cloud or another network file system that does not allow setting permissions on files.                       | true                                                                                                                                                                                                                                                                          | no                       |
| HYKU_FILE_SIZE_LIMIT             | How big a file do you want to accept in the work upload?                                                                                                                 | 5242880 (5 MB)                                                                                                                                                                                                                                                                | no                       |
| HYKU_GEONAMES_USERNAME           | Username used for Geonames connections by the application                                                                                                                | ''                                                                                                                                                                                                                                                                            | no                       |
| HYKU_GOOGLE_SCHOLARLY_WORK_TYPES | List of work types which should be presented to Google Scholar for indexing. Comma separated WorkType list                                                               | -                                                                                                                                                                                                                                                                             | no                       |
| HYKU_GTM_ID                      | If set, enable Google Tag manager with this id.                                                                                                                          | -                                                                                                                                                                                                                                                                             | no                       |
| HYKU_LOCALE_NAME                 | Not used. Placeholder for upcoming Ubiquity feature                                                                                                                      | en                                                                                                                                                                                                                                                                            | no                       |
| HYKU_MONTHLY_EMAIL_LIST          | Not used. Placeholder for upcoming Ubiquity feature                                                                                                                      | en                                                                                                                                                                                                                                                                            | no                       |
| HYKU_MULTITENANT                 | Set application up for multitenantcy, or use the single tenant version.                                                                                                  | false                                                                                                                                                                                                                                                                         | no                       |
| HYKU_OAI_ADMIN_EMAIL             | OAI endpoint contact address                                                                                                                                             | changeme@example.com                                                                                                                                                                                                                                                          | no                       |
| HYKU_OAI_PREFIX                  | OAI namespace metadata prefix                                                                                                                                            | oai:hyku                                                                                                                                                                                                                                                                      | no                       |
| HYKU_OAI_SAMPLE_IDENTIFIER       | OAI example of what an identify might look like                                                                                                                          | 806bbc5e-8ebe-468c-a188-b7c14fbe34df                                                                                                                                                                                                                                          | no                       |
| HYKU_ROOT_HOST                   | What is the very base url that default subdomains should be tacked on to?                                                                                                | hyku.test                                                                                                                                                                                                                                                                     | no                       |
| HYKU_S3_BUCKET                   | If set basic uploads for things like branding images will be sent to S3                                                                                                  | -                                                                                                                                                                                                                                                                             | no                       |
| HYKU_SHARED_LOGIN                | Not used. Placeholder for upcoming Ubiquity feature                                                                                                                      | en                                                                                                                                                                                                                                                                            | no                       |
| HYKU_SMTP_SETTINGS               | String representing a hash of options for tenant specific SMTP defaults. Can be any of `from user_name password address domain port authentication enable_starttls_auto` | -                                                                                                                                                                                                                                                                             | no                       |
| HYKU_SOLR_COLLECTION_OPTIONS     | Overrides of specific collection options for Solr.                                                                                                                       | `{async: nil, auto_add_replicas: nil, collection: { config_name: ENV.fetch('SOLR_CONFIGSET_NAME', 'hyku') }, create_node_set: nil, max_shards_per_node: nil, num_shards: 1, replication_factor: nil, router: { name: nil, field: nil }, rule: nil, shards: nil, snitch: nil}` | no                       |
| HYKU_SSL_CONFIGURED              | Force SSL on page loads and IIIF manifest links                                                                                                                          | false                                                                                                                                                                                                                                                                         | no                       |
| HYKU_WEEKLY_EMAIL_LIST           | Not used. Placeholder for upcoming Ubiquity feature                                                                                                                      | en                                                                                                                                                                                                                                                                            | no                       |
| HYKU_YEARLY_EMAIL_LIST           | Not used. Placeholder for upcoming Ubiquity feature                                                                                                                      | en                                                                                                                                                                                                                                                                            | no                       |
| HYRAX_ACTIVE_JOB_QUEUE           | Which Rails background job runner should be used?                                                                                                                        | sidekiq                                                                                                                                                                                                                                                                       | no                       |
| HYRAX_FITS_PATH                  | Where is fits.sh installed on the system. Will try the PATH if not set.                                                                                                  | /app/fits/fits.sh                                                                                                                                                                                                                                                             | no                       |
| HYRAX_REDIS_NAMESPACE            | What namespace should the application use by default                                                                                                                     | hyrax                                                                                                                                                                                                                                                                         | no                       |
| I18N_DEBUG                       | See [Working with Translations] above                                                                                                                                    | false                                                                                                                                                                                                                                                                         | yes                      |
| INITIAL_ADMIN_EMAIL              | Admin email used by database seeds.                                                                                                                                      | admin@example.com                                                                                                                                                                                                                                                             | no                       |
| INITIAL_ADMIN_PASSWORD           | Admin password used by database seeds. Be sure to change in production.                                                                                                  | testing123                                                                                                                                                                                                                                                                    | no                       |
| IN_DOCKER                        | Used specs to know if we are running inside a container or not. Set to true if in K8S regardless of Docker vs ContainerD                                                 | false                                                                                                                                                                                                                                                                         | yes                      |
| LD_LIBRARY_PATH                  | Path used for fits                                                                                                                                                       | /app/fits/tools/mediainfo/linux                                                                                                                                                                                                                                               | no                       |
| NEGATIVE_CAPTCHA_SECRET          | A secret value you set for the appliations negative_captcha to work.                                                                                                     | default-value-change-me                                                                                                                                                                                                                                                       | no                       |
| RAILS_ENV                        | https://guides.rubyonrails.org/configuring.html#creating-rails-environments                                                                                              | development                                                                                                                                                                                                                                                                   | no                       |
| RAILS_LOG_TO_STDOUT              | Redirect all logging to stdout                                                                                                                                           | true                                                                                                                                                                                                                                                                          | no                       |
| RAILS_MAX_THREADS                | Number of threads to use in puma or sidekiq                                                                                                                              | 5                                                                                                                                                                                                                                                                             | no                       |
| REDIS_HOST                       | Host location of redis                                                                                                                                                   | redis                                                                                                                                                                                                                                                                         | no                       |
| REDIS_PASSWORD                   | Password for redis, optional                                                                                                                                             | -                                                                                                                                                                                                                                                                             | no                       |
| REDIS_URL                        | Optional explicit redis url, build from host/passsword if not specified                                                                                                  | redis://:staging@redis:6397/                                                                                                                                                                                                                                                  | no                       |
| REPOSITORY_S3_STORAGE            | Whether to turn on S3 or S3 like storage for Valkyrie or not                                                                                                             | false                                                                                                                                                                                                                                                                         | no                       |
| REPOSITORY_S3_BUCKET             | If storing file uploads in S3, what bucket should they be put in                                                                                                         | -                                                                                                                                                                                                                                                                             | no                       |
| REPOSITORY_S3_REGION             | Region code for S3 like storage                                                                                                                                          | -                                                                                                                                                                                                                                                                             | no                       |
| REPOSITORY_S3_ACCESS_KEY         | Access key for S3 like storage                                                                                                                                           | -                                                                                                                                                                                                                                                                             | no                       |
| REPOSITORY_S3_SECRET_KEY         | The secret key for S3 like storage                                                                                                                                       | -                                                                                                                                                                                                                                                                             | no                       |
| REPOSITORY_S3_ENDPOINT           | Needed for S3 like storage such as Minio or custom S3 endpoints                                                                                                          | -                                                                                                                                                                                                                                                                             | no                       |
| REPOSITORY_S3_PORT               | Only needed for S3 like storage like Minio                                                                                                                               | -                                                                                                                                                                                                                                                                             | no                       |
| SECRET_KEY_BASE                  | Used by Rails to secure sessions, should be a 128 character hex                                                                                                          | -                                                                                                                                                                                                                                                                             | no                       |
| SMTP_ADDRESS                     | Address of the smtp endpoint for sending email                                                                                                                           | -                                                                                                                                                                                                                                                                             | no                       |
| SMTP_DOMAIN                      | Domain for sending email                                                                                                                                                 | -                                                                                                                                                                                                                                                                             | no                       |
| SMTP_PASSWORD                    | Password for email sending                                                                                                                                               | -                                                                                                                                                                                                                                                                             | no                       |
| SMTP_PORT                        | Port for email sending                                                                                                                                                   | -                                                                                                                                                                                                                                                                             | no                       |
| SMTP_USER_NAME                   | Username for the email connection                                                                                                                                        | -                                                                                                                                                                                                                                                                             | no                       |
| SOLR_ADMIN_PASSWORD              | Solr requires a user/password when accessing the collections API (which we use to create and manage solr collections and aliases)                                        | admin                                                                                                                                                                                                                                                                         | no                       |
| SOLR_ADMIN_USER                  | Solr requires a user/password when accessing the collections API (which we use to create and manage solr collections and aliases)                                        | admin                                                                                                                                                                                                                                                                         | no                       |
| SOLR_COLLECTION_NAME             | Name of the Solr collection used by non-tenant search. This is required by Hyrax, but is currently unused by Hyku                                                        | hydra-development                                                                                                                                                                                                                                                             | no                       |
| SOLR_CONFIGSET_NAME              | Name of the Solr configset to use when creating new Solr collections                                                                                                     | hyku                                                                                                                                                                                                                                                                          | no                       |
| SOLR_HOST                        | Host for the Solr connection                                                                                                                                             | solr                                                                                                                                                                                                                                                                          | no                       |
| SOLR_PORT                        | Solr port                                                                                                                                                                | 8983                                                                                                                                                                                                                                                                          | no                       |
| SOLR_URL                         | URL for the Solr connection                                                                                                                                              | http://admin:admin@solr:8983/solr/                                                                                                                                                                                                                                            | no                       |
| WEB_CONCURRENCY                  | Number of processes to run in either puma or sidekiq                                                                                                                     | 2                                                                                                                                                                                                                                                                             | no                       |

## Single Tenant Mode

Much of the default configuration in Hyku is set up to use multi-tenant mode. This default mode allows Hyku users to run the equivielent of multiple Hyrax installs on a single set of resources. However, sometimes the subdomain splitting multi-headed complexity is simply not needed. If this is the case, then single tenant mode is for you. Single tenant mode will not show the tenant sign up page, or any of the tenant management screens. Instead it shows a single Samvera instance at what ever domain is pointed at the application.

To enable single tenant, set `HYKU_MULTITENANT=false` in your `docker-compose.yml` and `docker-compose.production.yml` configs. After changinig this setting, run `rails db:seed` to prepopulate the single tenant.

In single tenant mode, both the application root (eg. localhost, or hyku.test) and the tenant url single.\* (eg. single.hyku.test) will load the tenant. Override the root host by setting HYKU_ROOT_HOST`.

To change from single- to multi-tenant mode, change the multitenancy/enabled flag to true and restart the application. Change the 'single' tenant account cname in the Accounts edit interface to the correct hostname.

## Google Analytics 4 (GA4) Setup

Hyku supports Google Analytics 4 for tracking user interactions and generating analytics reports. GA4 was added in Hyku v6.0 and provides tenant-specific analytics isolation.

> **📖 Complete Setup Guide:** For detailed instructions, see the [official Samvera GA4 documentation](https://samvera.atlassian.net/wiki/spaces/hyku/pages/3185147970/Google+Analytics+4+GA4+Support#Creating-a-New-Google-Analytics-Account)

### Quick Setup Overview

**📋 Setup Sequence (MUST be done in this order):**

1. **Global Admin**: Set up Google Cloud + GA4 properties
2. **Developer**: Configure global environment variables + restart app
3. **Tenants**: Configure individual tenant analytics settings

#### 1. 🌐 Global Administrator Setup

**Google Cloud Console:**

1. Create a Google Cloud project
2. Create a **Service Account** (ends with `@PROJECT.iam.gserviceaccount.com`)
3. Generate and download the **JSON key file**
4. Enable **Google Analytics Data API**

**Google Analytics:**

1. Create GA4 **Properties** (one per tenant for data isolation)
2. Add your **Service Account email** to each property with **Viewer** access
3. Note the **Measurement ID** (`G-XXXXXXXXXX`) and **Property ID** (numeric) for each
4. **Configure Required Custom Dimensions** (see section below)

#### 2. 🔧 Developer Environment Setup

⚠️ **CRITICAL:** These global environment variables **must be configured BEFORE** tenants can set up their individual analytics properties.

**Required Global Environment Variables:**

```bash
# Enable GA4 globally across all tenants
HYRAX_ANALYTICS=true
HYRAX_ANALYTICS_REPORTING=true
HYRAX_ANALYTICS_PROVIDER=ga4

# Global Service Account JSON (REQUIRED - obtained from step 1)
GOOGLE_ACCOUNT_JSON='{"type":"service_account","project_id":"your-project-name","private_key_id":"PRIVATE_KEY_ID_HERE","private_key":"-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_CONTENT_HERE\n-----END PRIVATE KEY-----\n","client_email":"your-service-account@your-project-name.iam.gserviceaccount.com","client_id":"CLIENT_ID_HERE","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/your-service-account%40your-project-name.iam.gserviceaccount.com","universe_domain":"googleapis.com"}'

# Optional: Global fallback analytics IDs (if not set per-tenant)
GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX
GOOGLE_ANALYTICS_PROPERTY_ID=NUMERIC_PROPERTY_ID
```

**How to Set These Variables:**

**For Docker Compose Development:**
Create or update your `.env` file in the project root:

```bash
echo 'HYRAX_ANALYTICS=true' >> .env
echo 'HYRAX_ANALYTICS_REPORTING=true' >> .env
echo 'HYRAX_ANALYTICS_PROVIDER=ga4' >> .env
echo 'GOOGLE_ACCOUNT_JSON={"type":"service_account","project_id":"YOUR_PROJECT",...}' >> .env
```

**For Docker Compose (docker-compose.yml):**

```yaml
services:
  web:
    environment:
      - HYRAX_ANALYTICS=true
      - HYRAX_ANALYTICS_REPORTING=true
      - HYRAX_ANALYTICS_PROVIDER=ga4
      - GOOGLE_ACCOUNT_JSON={"type":"service_account","project_id":"YOUR_PROJECT",...}
```

**For Production Deployment:**

- Set as environment variables in your hosting platform
- Store `GOOGLE_ACCOUNT_JSON` as a secure secret (not in plain text config)
- Consider using external secret management (Kubernetes secrets, AWS Secrets Manager, etc.)

#### 2.5. 📊 Required GA4 Custom Dimensions Setup

⚠️ **CRITICAL**: Each GA4 property **must** have these custom dimensions configured for Hyku analytics to work properly.

**Why Custom Dimensions Are Required:**

- **Tenant Isolation**: The `tenant_id` dimension ensures analytics data is properly isolated between tenants in multi-tenant installations
- **Content Tracking**: Hyku tracks different types of content (works, collections, file sets) and needs proper dimensioning
- **Backwards Compatibility**: Without these dimensions, analytics reports will fail with "invalid dimension" errors

**Required Custom Dimensions:**

| Parameter Name | Display Name | Description                                | Scope | Required For                   |
| -------------- | ------------ | ------------------------------------------ | ----- | ------------------------------ |
| `tenant_id`    | Tenant ID    | Multi-tenant identifier for data isolation | Event | **Multi-tenant** installations |

**Note:** `content_id` and `content_type` are standard GA4 event parameters and should be available automatically. You only need to manually create the `tenant_id` custom dimension for multi-tenant installations.

**How to Create Custom Dimensions:**

1. **Go to GA4 Property**: Admin → Custom definitions → Custom dimensions
2. **Create the tenant_id dimension** with the exact parameter name above
3. **Verify Setup**: Check that the tenant_id dimension appears in your custom dimensions list

**Step-by-Step Instructions:**

1. In GA4, navigate to **Admin** → **Custom definitions** → **Custom dimensions**
2. Click **"Create custom dimension"**
3. For the **tenant_id dimension**:
   - **Dimension name**: "Tenant ID"
   - **Scope**: Select "Event"
   - **Parameter name**: `tenant_id` (case-sensitive)
   - **Description**: "Multi-tenant identifier for data isolation"
4. Click **"Save"**

**⚠️ Common Mistakes:**

- **Wrong parameter name**: Must be exactly `tenant_id` (case-sensitive)
- **Wrong scope**: Must be "Event" scope, not "User" or "Item" scope
- **Only for multi-tenant**: Single-tenant installations don't need this dimension

**Verification:**
After creating the dimension, you should see `tenant_id` in your GA4 property's custom dimensions list. If missing, analytics reports will fail.

#### 3. 🏢 Tenant Configuration

⚠️ **Prerequisites:**

- Global environment variables must be set (step 2)
- Application must be restarted after setting global variables
- **CRITICAL**: Each tenant must grant access to the administrator's service account

**Required Tenant Action - Grant Access to Administrator:**

After the global administrator sets up the service account, **each tenant must manually add the administrator's service account email to their GA4 property access management:**

1. **Get the Service Account Email**: The administrator should provide tenants with the service account email (format: `something@project-name.iam.gserviceaccount.com`)
2. **Add to GA4 Property**: Each tenant must go to their GA4 property → Admin → Property Access Management
3. **Grant Viewer Access**: Add the service account email with **Viewer** role access
4. **Wait for Propagation**: Access changes may take up to 24 hours to fully propagate

**Why This is Required:**

- The global service account (configured by the administrator) needs access to each tenant's GA4 property to fetch analytics data
- Without this access, analytics will fail silently and no data will be displayed
- This is a Google Analytics security requirement - external accounts cannot access GA4 data without explicit permission

**Complete Tenant Setup in Hyku:**

Once access is granted, each tenant configures their specific GA4 property in **Admin → Settings:**

- **Google Analytics ID**: Measurement ID (`G-XXXXXXXXXX`)
- **Google Analytics Property ID**: Numeric Property ID (`NUMERIC_PROPERTY_ID`)
- Enable **Analytics** and **Analytics Reporting** checkboxes

**Important:** Each tenant needs their own dedicated GA4 property for data isolation. The global service account must have Viewer access to each tenant's GA4 property for the integration to work.

### 🔐 Security & Access

- **Service Account** must have **Viewer** access to each GA4 property
- **JSON key** should be stored securely (environment variables, not in code)
- Each tenant gets isolated analytics data from their dedicated GA4 property
- **Tenant Responsibility**: Each tenant must explicitly grant the administrator's service account access to their GA4 property
- **Access Propagation**: Google Analytics access changes may take up to 24 hours to fully activate

### 🚨 Common Error Resolution

#### 1. Google Analytics Data API Permission Error

**Error Message:**

```
Google::Cloud::PermissionDeniedError: Google Analytics Data API has not been used in project [PROJECT_ID] before or it is disabled.
```

**Solution:**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to **APIs & Services** → **Library**
4. Search for "Google Analytics Data API"
5. Click on it and press **Enable**
6. Wait a few minutes for the API to become active

**Alternative Quick Link:**

- Replace `[PROJECT_ID]` with your actual project ID in this URL:
  `https://console.developers.google.com/apis/api/analyticsdata.googleapis.com/overview?project=[PROJECT_ID]`

#### 2. Custom Dimension Missing Error

**Error Message:**

```
Google::Cloud::InvalidArgumentError: Field customEvent:tenant_id is not a valid dimension.
```

**Solution:**

1. Go to your Google Analytics 4 property
2. Navigate to **Admin** → **Custom definitions** → **Custom dimensions**
3. Click **"Create custom dimensions"**
4. Set **Dimension name** to: `tenant_id`
5. Set **Scope** to: `Event`
6. Click **"Save"**
7. **Important:** Wait up to 24 hours for the dimension to become available

**Why This is Required:**

- The `tenant_id` custom dimension is essential for multi-tenant analytics isolation
- Without it, analytics queries will fail with "invalid dimension" errors
- This dimension must be created at the GA4 property level

#### 3. Service Account Access Issues

**Error Message:**

```
Google::Cloud::PermissionDeniedError: Access denied to Google Analytics property
```

**Solution:**

1. Ensure your service account has **Viewer** access to the GA4 property
2. Go to **GA4 Admin** → **Property Access Management**
3. Add your service account email with **Viewer** role
4. Wait up to 24 hours for access changes to propagate

#### 4. JSON Credentials Format Issues

**Error Message:**

```
JSON::ParserError: invalid ASCII control character in string
```

**Solution:**

1. Ensure your `GOOGLE_ACCOUNT_JSON` environment variable is properly escaped
2. Use the provided Ruby script to format the JSON correctly:
   ```bash
   ruby format_google_account_json.rb path/to/your/service-account.json
   ```
3. Copy the output and set it as your environment variable

**Ruby Script for JSON Formatting:**
Create a file called `format_google_account_json.rb` with this content:

```ruby
#!/usr/bin/env ruby
require "json"

def format_google_account_json(json_file_path)
  raw = File.read(json_file_path)
  parsed = JSON.parse(raw)
  min = JSON.generate(parsed)
  escaped = min.gsub('"', '\"')
  puts %(export GOOGLE_ACCOUNT_JSON="#{escaped}")
end

if ARGV.length != 1
  warn "Usage: #{$0} <json_file>"
  exit 1
end

format_google_account_json(ARGV[0])
```

Then run it with your service account JSON file:

```bash
ruby format_google_account_json.rb path/to/your-service-account.json
```

Copy the output and use it to set your environment variable.

### 🐛 General Troubleshooting

**No data showing:**

- Verify service account has access to the GA4 property
- Check that the Measurement ID format is correct (`G-XXXXXXXXXX`)
- Ensure `GOOGLE_ACCOUNT_JSON` environment variable is properly escaped
- **Verify custom dimensions**: Ensure all required custom dimensions (`tenant_id`, `content_id`, `content_type`) are created in GA4

**Authentication errors:**

- Verify the JSON key is valid and properly formatted
- Check that Google Analytics Data API is enabled in Google Cloud Console
- **Most Common Issue**: Ensure the service account email exists in GA4 property access management
- Verify the service account has **Viewer** access (not Editor or Admin)
- Check that access was granted at the **Property** level, not just the Account level
- Remember that access changes can take up to 24 hours to propagate

**No data showing (most common issue):**

- **Check Service Account Access**: Verify the administrator's service account has been added to the tenant's GA4 property with Viewer access
- **Verify Property ID**: Ensure the Property ID is numeric (not the Measurement ID)
- **Check Tenant Settings**: Confirm Analytics and Analytics Reporting are enabled in Admin → Settings
- **Wait for Propagation**: If access was just granted, wait up to 24 hours for Google Analytics to fully activate the permissions

**"Invalid dimension" or "Field X is not a valid dimension" errors:**

- **Most Common Cause**: Missing or incorrectly named custom dimensions in GA4
- **Solution**: Verify all three required custom dimensions are created with exact parameter names:
  - `tenant_id` (for multi-tenant installations)
  - `content_id` (required for all installations)
  - `content_type` (required for all installations)
- **Check**: Go to GA4 → Admin → Custom definitions → Custom dimensions to verify
- **Note**: Parameter names are case-sensitive and must match exactly

### 📊 Analytics Features

When properly configured, Hyku provides:

- **Page views** and **visitor analytics**
- **Work and collection** view statistics
- **File download** tracking
- **Dashboard reports** with tenant-specific data isolation
- **Optional email reports** to depositors

### 🔄 Legacy Universal Analytics

⚠️ **Universal Analytics (UA) is deprecated.** Google stopped processing UA data on July 1, 2023. Migrate to GA4 for continued analytics support.

## Working with Translations

You can log all of the I18n lookups to the Rails logger by setting the I18N_DEBUG environment variable to true. This will add a lot of chatter to the Rails logger (but can be very helpful to zero in on what I18n key you should or could use).

```console
$ I18N_DEBUG=true bin/rails server
```

## S3 Like Storage

You can upload your primary works to S3 in Valkyrie mode by turning on `REPOSITORY_S3_STORAGE` and setting the accompanying bucket and credentials variables. This enables both AWS S3 and other S3 like storage engines such as Minio. As of this writing this only affects Valkyrie resources and only the primary storage. Derivatives, uploads and branding assets all still go to the shared storage directories.
