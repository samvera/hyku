# frozen_string_literal: true

RSpec.describe AccountSettings do
  let(:account) { FactoryBot.create(:account) }

  describe '#public_settings' do
    context 'when is_superadmin is true' do
      # rubocop:disable RSpec/ExampleLength
      it 'returns all settings except private and disabled settings' do
        expect(account.public_settings(is_superadmin: true).keys.sort).to eq %i[allow_downloads
                                                                                allow_signup
                                                                                analytics_provider
                                                                                bulkrax_field_mappings
                                                                                cache_api
                                                                                contact_email
                                                                                contact_email_to
                                                                                doi_reader
                                                                                doi_writer
                                                                                email_domain
                                                                                email_format
                                                                                email_subject_prefix
                                                                                file_acl
                                                                                file_size_limit
                                                                                geonames_username
                                                                                google_analytics_id
                                                                                gtm_id
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

    context 'when we have a field marked as superadmin only' do
      before { account.superadmin_settings = %i[analytics_provider] }
      context 'and we are not a super admin' do
        it 'does not include that field' do
          expect(account.public_settings(is_superadmin: false).keys).not_to include(:analytics_provider)
        end
      end

      context 'and we are a super admin' do
        it 'includes that field' do
          expect(account.public_settings(is_superadmin: true).keys).to include(:analytics_provider)
        end
      end
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
        expect(account.errors.messages[:bulkrax_field_mappings]).to eq(["unexpected token at 'hello world'"])
      end
    end
  end
end
