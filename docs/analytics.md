# Analytics Configuration

Hyku supports multiple analytics providers for tracking user interactions and displaying analytics data in the dashboard. Currently supported providers are:

- **Google Analytics 4 (GA4)** - Current analytics platform
- **Matomo** - Self-hosted analytics solution

## Analytics Provider Selection

The analytics provider is configured globally via the `HYRAX_ANALYTICS_PROVIDER` environment variable:

```bash
# For Google Analytics 4 (recommended)
HYRAX_ANALYTICS_PROVIDER=ga4

# For Google Analytics 4 (GA4)
HYRAX_ANALYTICS_PROVIDER=google

# For Matomo
HYRAX_ANALYTICS_PROVIDER=matomo
```

**Note**: Universal Analytics was deprecated by Google on July 1, 2023. Hyku now only supports Google Analytics 4 (GA4) format.

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

## Tenant-Specific Analytics Configuration

Once the global analytics provider is configured, individual tenants can:

1. **Enable/Disable Analytics**: Each tenant can enable or disable analytics for their site
2. **Override Global Settings**: For Google Analytics, tenants can provide their own:
   - Google Analytics Measurement ID (GA4 format: G-XXXXXXXXXX)
   - Google Analytics Property ID (GA4 only)
3. **Analytics Dashboard Access**: The analytics dashboard and reports are only visible to tenants who have configured their own analytics credentials

**Note**: When both global and tenant-specific analytics are configured, both will track user interactions (dual tracking). The analytics UI is only shown to tenants who have explicitly configured their own settings.
