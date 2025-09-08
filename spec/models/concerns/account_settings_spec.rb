# frozen_string_literal: true

RSpec.describe AccountSettings do
  let(:account) { FactoryBot.create(:account) }

  before do
    # Stub all ENV variables that might be called during account initialization
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('HYRAX_ANALYTICS_PROVIDER', 'ga4').and_return('ga4')
    allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_ID', '').and_return('')
    allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_PROPERTY_ID', '').and_return('')
    allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('')
    allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON_PATH', '').and_return('')
    allow(ENV).to receive(:fetch).with('MATOMO_BASE_URL', '').and_return('')
    allow(ENV).to receive(:fetch).with('MATOMO_SITE_ID', '').and_return('')
    allow(ENV).to receive(:fetch).with('MATOMO_AUTH_TOKEN', '').and_return('')
  end

  describe '#public_settings' do
    context 'when is_superadmin is true' do
      # rubocop:disable RSpec/ExampleLength
      it 'returns all settings except private and disabled settings' do
        expect(account.public_settings(is_superadmin: true).keys.sort).to eq %i[allow_downloads
                                                                                allow_signup
                                                                                analytics
                                                                                batch_email_notifications
                                                                                bulkrax_field_mappings
                                                                                cache_api
                                                                                contact_email
                                                                                contact_email_to
                                                                                depositor_email_notifications
                                                                                discogs_user_token
                                                                                doi_reader
                                                                                doi_writer
                                                                                email_domain
                                                                                email_format
                                                                                email_subject_prefix
                                                                                file_acl
                                                                                file_size_limit
                                                                                geonames_username
                                                                                google_analytics_id
                                                                                google_analytics_property_id
                                                                                gtm_id
                                                                                hidden_index_fields
                                                                                oai_admin_email
                                                                                oai_prefix
                                                                                oai_sample_identifier
                                                                                s3_bucket
                                                                                smtp_settings
                                                                                solr_collection_options
                                                                                ssl_configured]
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end

  describe '#bulkrax_field_mappings' do
    context 'when the setting is blank' do
      it 'returns the default field mappings configured in Hyku' do
        expect(account.settings['bulkrax_field_mappings']).to be_nil
        # For parity, parse field mappings from JSON. #to_json will stringify keys as
        # well as turn a regex like /\|/ into (?-mix:\\|)
        default_bulkrax_mappings = JSON.parse(Hyku.default_bulkrax_field_mappings.to_json)
        default_tenant_mappings = JSON.parse(account.bulkrax_field_mappings)

        expect(default_tenant_mappings).to eq(default_bulkrax_mappings)
      end
    end

    context 'when the setting is present' do
      let(:account) { build(:account, settings: { bulkrax_field_mappings: setting_value }) }

      context 'when the value is valid JSON' do
        let(:setting_value) do
          {
            'Bulkrax::CsvParser' => {
              'fake_field' => { from: %w[fake_column], split: /\s*[|]\s*/ }
            }
          }.to_json
        end

        it 'parses the JSON into a Hash and prints it as pretty JSON' do
          expect(account.bulkrax_field_mappings)
            .to eq(JSON.pretty_generate(JSON.parse(setting_value)))
        end
      end

      context 'when the value is not valid JSON' do
        let(:setting_value) { 'hello world' }

        it 'returns the raw value' do
          expect(account.bulkrax_field_mappings).to eq(setting_value)
        end
      end
    end
  end

  describe '#validate_json' do
    let(:account) { build(:account, settings: { bulkrax_field_mappings: setting_value }) }

    context 'when a "json_editor" setting is valid JSON' do
      let(:setting_value) { { a: 'b' }.to_json }

      it 'does not error' do
        expect(account.valid?).to eq(true)
      end
    end

    context 'when a "json_editor" setting is not valid JSON' do
      let(:setting_value) { 'hello world' }

      it 'adds an error to the setting' do
        expect(account.valid?).to eq(false)
        expect(account.errors.messages[:bulkrax_field_mappings]).to eq(["unexpected character: 'hello' at line 1 column 1"])
      end
    end
  end

  describe 'consolidated analytics setting' do
    describe '#analytics' do
      context 'when analytics setting is not present' do
        it 'returns the default value (false)' do
          expect(account.analytics).to be false
        end
      end

      context 'when analytics setting is present' do
        before { account.settings['analytics'] = true }

        it 'returns the set value' do
          expect(account.analytics).to be true
        end
      end
    end

    describe 'Google Analytics form display methods' do
      describe '#google_analytics_id' do
        context 'when tenant has no specific value and ENV is set' do
          before do
            account.settings['google_analytics_id'] = nil
            allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_ID', '').and_return('G-ENVVALUE123')
          end

          it 'returns empty string for form display (not ENV value)' do
            expect(account.google_analytics_id).to eq('')
          end
        end

        context 'when tenant has a specific value' do
          before { account.settings['google_analytics_id'] = 'G-TENANT123' }

          it 'returns the tenant-specific value' do
            expect(account.google_analytics_id).to eq('G-TENANT123')
          end
        end
      end

      describe '#google_analytics_property_id' do
        context 'when tenant has no specific value and ENV is set' do
          before do
            account.settings['google_analytics_property_id'] = nil
            allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_PROPERTY_ID', '').and_return('987654321')
          end

          it 'returns empty string for form display (not ENV value)' do
            expect(account.google_analytics_property_id).to eq('')
          end
        end

        context 'when tenant has a specific value' do
          before { account.settings['google_analytics_property_id'] = '123456789' }

          it 'returns the tenant-specific value' do
            expect(account.google_analytics_property_id).to eq('123456789')
          end
        end
      end
    end

    describe '#configure_hyrax_analytics_settings' do
      let(:config) { double('config') }

      context 'when analytics credentials are functionally available' do
        before do
          allow(account).to receive(:analytics_functionally_available?).and_return(true)
        end

        it 'enables analytics and analytics_reporting in Hyrax config' do
          expect(config).to receive(:analytics=).with(true)
          expect(config).to receive(:analytics_reporting=).with(true)

          account.configure_hyrax_analytics_settings(config)
        end
      end

      context 'when analytics credentials are not functionally available' do
        before do
          allow(account).to receive(:analytics_functionally_available?).and_return(false)
        end

        it 'disables analytics and analytics_reporting in Hyrax config' do
          expect(config).to receive(:analytics=).with(false)
          expect(config).to receive(:analytics_reporting=).with(false)

          account.configure_hyrax_analytics_settings(config)
        end
      end
    end

    describe '#analytics_credentials_present?' do
      context 'when tenant has specific analytics credentials' do
        it 'returns true when all tenant-specific credentials are present and analytics is enabled' do
          allow(account).to receive(:analytics).and_return(true)
          allow(account).to receive(:google_analytics_id).and_return('G-XXXXXXXXXX')
          allow(account).to receive(:google_analytics_property_id).and_return('123456789')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('{}')

          expect(account.analytics_credentials_present?).to be true
        end

        it 'returns false when analytics is disabled even with valid credentials' do
          allow(account).to receive(:analytics).and_return(false)
          allow(account).to receive(:google_analytics_id).and_return('G-XXXXXXXXXX')
          allow(account).to receive(:google_analytics_property_id).and_return('123456789')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('{}')

          expect(account.analytics_credentials_present?).to be false
        end

        # rubocop:disable RSpec/ExampleLength
        it 'returns false when tenant google_analytics_id is missing' do
          allow(account).to receive(:analytics).and_return(true)
          allow(account).to receive(:google_analytics_id).and_return('')
          allow(account).to receive(:google_analytics_property_id).and_return('123456789')
          allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_ID', '').and_return('')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('{}')

          expect(account.analytics_credentials_present?).to be false
        end
        # rubocop:enable RSpec/ExampleLength
      end

      context 'when tenant has no specific credentials but ENV has them' do
        # rubocop:disable RSpec/ExampleLength
        it 'returns false when only ENV credentials are present (tenant has no specific values)' do
          allow(account).to receive(:analytics).and_return(true)
          allow(account).to receive(:google_analytics_id).and_return('')
          allow(account).to receive(:google_analytics_property_id).and_return('')
          allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_ID', '').and_return('G-ENVXXXXXXX')
          allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_PROPERTY_ID', '').and_return('987654321')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('{}')
          expect(account.analytics_credentials_present?).to be false
        end
        # rubocop:enable RSpec/ExampleLength

        # rubocop:disable RSpec/ExampleLength
        it 'returns false when ENV credentials are also missing' do
          allow(account).to receive(:analytics).and_return(true)
          allow(account).to receive(:google_analytics_id).and_return('')
          allow(account).to receive(:google_analytics_property_id).and_return('')
          allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_ID', '').and_return('')
          allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_PROPERTY_ID', '').and_return('')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON_PATH', '').and_return('')
          expect(account.analytics_credentials_present?).to be false
        end
        # rubocop:enable RSpec/ExampleLength
      end

      context 'when tenant credentials override ENV credentials' do
        it 'uses tenant credentials even when ENV has different values' do
          allow(account).to receive(:analytics).and_return(true)
          allow(account).to receive(:google_analytics_id).and_return('G-TENANTXXX')
          allow(account).to receive(:google_analytics_property_id).and_return('111111111')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('{}')

          expect(account.analytics_credentials_present?).to be true
        end
      end

      # rubocop:disable RSpec/ExampleLength
      it 'returns false when JSON environment variables are missing' do
        allow(account).to receive(:analytics).and_return(true)
        allow(account).to receive(:google_analytics_id).and_return('G-XXXXXXXXXX')
        allow(account).to receive(:google_analytics_property_id).and_return('123456789')
        allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('')
        allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON_PATH', '').and_return('')

        expect(account.analytics_credentials_present?).to be false
      end
      # rubocop:enable RSpec/ExampleLength

      # rubocop:disable RSpec/ExampleLength
      it 'returns true when GOOGLE_ACCOUNT_JSON_PATH is present instead of GOOGLE_ACCOUNT_JSON' do
        allow(account).to receive(:analytics).and_return(true)
        allow(account).to receive(:google_analytics_id).and_return('G-XXXXXXXXXX')
        allow(account).to receive(:google_analytics_property_id).and_return('123456789')
        allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('')
        allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON_PATH', '').and_return('/path/to/service-account.json')

        expect(account.analytics_credentials_present?).to be true
      end
      # rubocop:enable RSpec/ExampleLength
    end

    describe '#analytics_functionally_available?' do
      context 'when tenant has specific analytics credentials' do
        it 'returns true when all tenant-specific credentials are present' do
          allow(account).to receive(:google_analytics_id).and_return('G-XXXXXXXXXX')
          allow(account).to receive(:google_analytics_property_id).and_return('123456789')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('{}')

          expect(account.analytics_functionally_available?).to be true
        end

        it 'returns false when tenant google_analytics_id is missing' do
          allow(account).to receive(:google_analytics_id).and_return('')
          allow(account).to receive(:google_analytics_property_id).and_return('123456789')
          allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_ID', '').and_return('')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('{}')

          expect(account.analytics_functionally_available?).to be false
        end
      end

      context 'when tenant has no specific credentials but ENV has them' do
        # rubocop:disable RSpec/ExampleLength
        it 'returns true when ENV credentials are present' do
          allow(account).to receive(:google_analytics_id).and_return('')
          allow(account).to receive(:google_analytics_property_id).and_return('')
          allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_ID', '').and_return('G-ENVXXXXXXX')
          allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_PROPERTY_ID', '').and_return('987654321')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('{}')

          expect(account.analytics_functionally_available?).to be true
        end
        # rubocop:enable RSpec/ExampleLength

        # rubocop:disable RSpec/ExampleLength
        it 'returns false when ENV credentials are also missing' do
          allow(account).to receive(:google_analytics_id).and_return('')
          allow(account).to receive(:google_analytics_property_id).and_return('')
          allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_ID', '').and_return('')
          allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_PROPERTY_ID', '').and_return('')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON_PATH', '').and_return('')

          expect(account.analytics_functionally_available?).to be false
        end
        # rubocop:enable RSpec/ExampleLength
      end

      context 'when tenant credentials override ENV credentials' do
        # rubocop:disable RSpec/ExampleLength
        it 'uses tenant credentials even when ENV has different values' do
          allow(account).to receive(:google_analytics_id).and_return('G-TENANTXXXX')
          allow(account).to receive(:google_analytics_property_id).and_return('111111111')
          allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_ID', '').and_return('G-ENVXXXXXXX')
          allow(ENV).to receive(:fetch).with('GOOGLE_ANALYTICS_PROPERTY_ID', '').and_return('987654321')
          allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('{}')

          expect(account.analytics_functionally_available?).to be true
        end
        # rubocop:enable RSpec/ExampleLength
      end

      it 'returns false when JSON environment variables are missing' do
        allow(account).to receive(:google_analytics_id).and_return('G-XXXXXXXXXX')
        allow(account).to receive(:google_analytics_property_id).and_return('123456789')
        allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('')
        allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON_PATH', '').and_return('')

        expect(account.analytics_functionally_available?).to be false
      end

      it 'returns true when GOOGLE_ACCOUNT_JSON_PATH is present instead of GOOGLE_ACCOUNT_JSON' do
        allow(account).to receive(:google_analytics_id).and_return('G-XXXXXXXXXX')
        allow(account).to receive(:google_analytics_property_id).and_return('123456789')
        allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON', '').and_return('')
        allow(ENV).to receive(:fetch).with('GOOGLE_ACCOUNT_JSON_PATH', '').and_return('/path/to/service-account.json')

        expect(account.analytics_functionally_available?).to be true
      end
    end

    context 'when analytics provider is matomo' do
      before do
        allow(ENV).to receive(:fetch).with('HYRAX_ANALYTICS_PROVIDER', 'ga4').and_return('matomo')
      end

      it 'returns true when all Matomo ENV variables are present' do
        allow(ENV).to receive(:fetch).with('MATOMO_BASE_URL', '').and_return('https://analytics.example.com')
        allow(ENV).to receive(:fetch).with('MATOMO_SITE_ID', '').and_return('42')
        allow(ENV).to receive(:fetch).with('MATOMO_AUTH_TOKEN', '').and_return('abc123')

        expect(account.analytics_functionally_available?).to be true
      end

      it 'returns false when Matomo ENV variables are missing' do
        allow(ENV).to receive(:fetch).with('MATOMO_BASE_URL', '').and_return('')
        allow(ENV).to receive(:fetch).with('MATOMO_SITE_ID', '').and_return('')
        allow(ENV).to receive(:fetch).with('MATOMO_AUTH_TOKEN', '').and_return('')

        expect(account.analytics_functionally_available?).to be false
      end

      it 'returns false when only some Matomo ENV variables are present' do
        allow(ENV).to receive(:fetch).with('MATOMO_BASE_URL', '').and_return('https://analytics.example.com')
        allow(ENV).to receive(:fetch).with('MATOMO_SITE_ID', '').and_return('')
        allow(ENV).to receive(:fetch).with('MATOMO_AUTH_TOKEN', '').and_return('abc123')

        expect(account.analytics_functionally_available?).to be false
      end
    end

    context 'when analytics provider is unknown' do
      before do
        allow(ENV).to receive(:fetch).with('HYRAX_ANALYTICS_PROVIDER', 'ga4').and_return('unknown_provider')
      end

      it 'returns false' do
        expect(account.analytics_functionally_available?).to be false
      end
    end
  end
end
