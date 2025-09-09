# Analytics Configuration

Hyku supports multiple analytics providers for tracking user interactions and displaying analytics data in the dashboard. Currently supported providers are:

- **Google Analytics 4 (GA4)** - Recommended for new implementations
- **Google Universal Analytics** - Legacy support (deprecated by Google)
- **Matomo** - Self-hosted analytics solution

## Analytics Provider Selection

The analytics provider is configured globally via the `HYRAX_ANALYTICS_PROVIDER` environment variable:

```bash
# For Google Analytics 4 (recommended)
HYRAX_ANALYTICS_PROVIDER=ga4

# For Google Universal Analytics (legacy)
HYRAX_ANALYTICS_PROVIDER=google

# For Matomo
HYRAX_ANALYTICS_PROVIDER=matomo
```

**Note**: Google has announced they will stop processing data using Universal Analytics on July 1, 2023 (or July 1, 2024 for Analytics 360 properties). New implementations should use Google Analytics 4.

To enable analytics tracking and reporting features within Hyku, please follow the provider-specific directions below.

## Google Analytics 4 (GA4) Setup

For new implementations, we recommend using Google Analytics 4:

1. **Create a Google Analytics 4 Property**:

   - Go to [Google Analytics](https://analytics.google.com/)
   - Create a new GA4 property
   - Note your **Measurement ID** (format: G-XXXXXXXXXX)
   - Note your **Property ID** (numeric, found in Property Details)

2. **Create a Service Account**:

   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a service account: https://cloud.google.com/iam/docs/creating-managing-service-accounts
   - Download the service account JSON key file
   - Add the service account email to your GA4 property with "Viewer" access

3. **Set Environment Variables**:
   ```bash
   HYRAX_ANALYTICS_PROVIDER=ga4
   GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX
   GOOGLE_ANALYTICS_PROPERTY_ID=123456789
   GOOGLE_ACCOUNT_JSON='{"type":"service_account",...}'
   # OR use a file path instead:
   GOOGLE_ACCOUNT_JSON_PATH=/path/to/service-account.json
   ```

## Google Universal Analytics Setup (Legacy)

For existing implementations using Universal Analytics:

1. **Create a Service Account**: https://cloud.google.com/iam/docs/creating-managing-service-accounts

- Note the service account email
- When making a service account key, make sure the key type is set to p12
- Note the service account private key secret

2. **Create an OAuth 2.0 Client ID**: https://developers.google.com/identity/protocols/oauth2/web-server#creatingcred
3. **Create an Analytics account**: https://support.google.com/analytics/answer/10269537?hl=en

- Note Google Universal Analytics ID number

4. **Add service account email as User, and grant "View" access**: https://support.google.com/analytics/answer/1009702?hl=en#Add&zippy=%2Cin-this-article
5. **Enable the "Google Analytics API"**: https://developers.google.com/identity/protocols/oauth2/web-server#enable-apis
6. **Enable the "IAM Service Account Credentials API"**: https://developers.google.com/identity/protocols/oauth2/web-server#enable-apis

## Matomo Setup

For self-hosted analytics using Matomo:

1. **Install and Configure Matomo**:

   - Install Matomo on your server: https://matomo.org/docs/installation/
   - Create a site in your Matomo installation
   - Note your **Site ID** and **Base URL**

2. **Create an Auth Token**:

   - In Matomo, go to Administration → Platform → API
   - Create a new auth token with appropriate permissions

3. **Set Environment Variables**:
   ```bash
   HYRAX_ANALYTICS_PROVIDER=matomo
   MATOMO_BASE_URL=https://your-matomo-instance.com
   MATOMO_SITE_ID=1
   MATOMO_AUTH_TOKEN=your-auth-token
   ```

## Set the Environment Variables

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
##START## Enable Analytics
# Uncomment to enable and configure analytics, see README for instructions.

# For Google Analytics 4 (recommended)
HYRAX_ANALYTICS_PROVIDER=ga4
GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX
GOOGLE_ANALYTICS_PROPERTY_ID=123456789
GOOGLE_ACCOUNT_JSON='{"type":"service_account",...}'
# OR use a file path instead:
# GOOGLE_ACCOUNT_JSON_PATH=/path/to/service-account.json

# For Google Universal Analytics (legacy)
# HYRAX_ANALYTICS_PROVIDER=google
# GOOGLE_ANALYTICS_ID=UA-123456-12
# GOOGLE_OAUTH_APP_NAME=hyku-demo
# GOOGLE_OAUTH_APP_VERSION=1.0
# GOOGLE_OAUTH_PRIVATE_KEY_SECRET=not-a-secret
# GOOGLE_OAUTH_PRIVATE_KEY_PATH=prod-cred.p12
# GOOGLE_OAUTH_CLIENT_EMAIL=set-me@email.com

# For Matomo
# HYRAX_ANALYTICS_PROVIDER=matomo
# MATOMO_BASE_URL=https://your-matomo-instance.com
# MATOMO_SITE_ID=1
# MATOMO_AUTH_TOKEN=your-auth-token

# AND comment this out
# HYRAX_ANALYTICS=false
##END## Enable Analytics
```

- For deployment to staging/production please update/add the variables and values to the helm values files located in the ops directory (example: staging-deploy.tmpl.yaml).

```yaml
# For Google Analytics 4 (recommended)
- name: HYRAX_ANALYTICS_PROVIDER
  value: "ga4"
  - name: GOOGLE_ANALYTICS_ID
    value: $GOOGLE_ANALYTICS_ID # Set in GitHub's Environment Secrets
- name: GOOGLE_ANALYTICS_PROPERTY_ID
  value: $GOOGLE_ANALYTICS_PROPERTY_ID # Set in GitHub's Environment Secrets
- name: GOOGLE_ACCOUNT_JSON
  value: $GOOGLE_ACCOUNT_JSON # Set in GitHub's Environment Secrets
# OR use a file path instead:
# - name: GOOGLE_ACCOUNT_JSON_PATH
#   value: /path/to/service-account.json

# For Google Universal Analytics (legacy)
# - name: HYRAX_ANALYTICS_PROVIDER
#   value: 'google'
# - name: GOOGLE_ANALYTICS_ID
#   value: $GOOGLE_ANALYTICS_ID # Set in GitHub's Environment Secrets
# - name: GOOGLE_OAUTH_APP_NAME
#   value: hyku-demo
# - name: GOOGLE_OAUTH_APP_VERSION
#   value: '1.0'
# - name: GOOGLE_OAUTH_PRIVATE_KEY_SECRET
#   value: $GOOGLE_OAUTH_PRIVATE_KEY_SECRET # Set in GitHub's Environment Secrets
# - name: GOOGLE_OAUTH_PRIVATE_KEY_PATH
#   value: prod-cred.p12 # The p12 file is in root and named `prod-cred.p12`
# - name: GOOGLE_OAUTH_PRIVATE_KEY_VALUE
#   value: $GOOGLE_OAUTH_PRIVATE_KEY_VALUE # Set in GitHub's Environment Secrets
# - name: GOOGLE_OAUTH_CLIENT_EMAIL
#   value: set-me@email.com

# For Matomo
# - name: HYRAX_ANALYTICS_PROVIDER
#   value: 'matomo'
# - name: MATOMO_BASE_URL
#   value: $MATOMO_BASE_URL # Set in GitHub's Environment Secrets
# - name: MATOMO_SITE_ID
#   value: $MATOMO_SITE_ID # Set in GitHub's Environment Secrets
# - name: MATOMO_AUTH_TOKEN
#   value: $MATOMO_AUTH_TOKEN # Set in GitHub's Environment Secrets

  - name: HYRAX_ANALYTICS
  value: "true"
```

To get the `GOOGLE_OAUTH_PRIVATE_KEY_VALUE` value to set the variable in GitHub's Environment Secrets, you need the path to the p12 file you got from setting up your Google Service Account and run the following in your console locally.

`base64 -i path/to/file.p12 | pbcopy`

Once you run this script the value is on your local computers clipboard. You will need to paste this into GitHubs Environment Secrets or however you/your organization are handling secrets.

## Tenant-Specific Analytics Configuration

Once the global analytics provider is configured, individual tenants can:

1. **Enable/Disable Analytics**: Each tenant can enable or disable analytics for their site
2. **Override Global Settings**: For Google Analytics, tenants can provide their own:
   - Google Analytics Measurement ID (GA4) or Universal Analytics ID
   - Google Analytics Property ID (GA4 only)
3. **Analytics Dashboard Access**: The analytics dashboard and reports are only visible to tenants who have configured their own analytics credentials

**Note**: When both global and tenant-specific analytics are configured, both will track user interactions (dual tracking). The analytics UI is only shown to tenants who have explicitly configured their own settings.
