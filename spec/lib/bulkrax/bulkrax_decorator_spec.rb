# frozen_string_literal: true

RSpec.describe Bulkrax::PerTenantFieldMappingDecorator, type: :decorator do
  before do
    allow(Site).to receive(:account).and_return(account)
  end

  context 'when the current Account does not have any tenant-specific field mappings' do
    let(:account) { build(:account) }

    context 'when Hyku.default_bulkrax_mapping_keys is unset' do
      before do
        allow(Hyku).to receive(:default_bulkrax_field_mappings).and_return nil
      end

      it "returns Bulkrax's default field mappings" do
        default_bulkrax_mapping_keys = ['Bulkrax::OaiDcParser', 'Bulkrax::OaiQualifiedDcParser', 'Bulkrax::CsvParser', 'Bulkrax::BagitParser', 'Bulkrax::XmlParser']

        expect(Site.account.settings['bulkrax_field_mappings']).to be_nil
        expect(Bulkrax.field_mappings).to be_a(Hash)
        expect(Bulkrax.field_mappings.keys.sort).to eq(default_bulkrax_mapping_keys.sort)
      end
    end

    context 'when Hyku.default_bulkrax_mapping_keys is set' do
      before do
        allow(Site.account).to receive(:bulkrax_field_mappings).and_return nil
      end

      around do |example|
        initialized_defaults = Hyku.default_bulkrax_field_mappings
        example.run
        Hyku.default_bulkrax_field_mappings = initialized_defaults
      end

      it "returns Hyku's default field mappings" do
        Hyku.default_bulkrax_field_mappings = { this: 'is fine' }

        expect(Site.account.settings['bulkrax_field_mappings']).to be_nil
        expect(Bulkrax.field_mappings).to be_a(Hash)
        expect(Bulkrax.field_mappings).to eq({ this: 'is fine' }.with_indifferent_access)
      end
    end
  end

  context 'when the current Account has tenant-specific field mappings' do
    let(:account) { build(:account, settings: { bulkrax_field_mappings: field_mapping_json }) }
    let(:field_mapping_json) do
      {
        'Bulkrax::CsvParser' => {
          'fake_field' => { from: %w[fake_column], split: /\s*[|]\s*/ }
        }
      }.to_json
    end

    it "returns the tenant's custom field mappings" do
      expect(Bulkrax.field_mappings).to eq(JSON.parse(Site.account.bulkrax_field_mappings))
    end
  end
end
