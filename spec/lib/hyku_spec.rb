# frozen_string_literal: true

RSpec.describe Hyku do
  it 'has a version' do
    expect(described_class).to have_constant(:VERSION)
  end

  describe '.multitenant?' do
    context 'when HYKU_MULTITENANT is "true"' do
      before { stub_const('ENV', ENV.to_h.merge('HYKU_MULTITENANT' => 'true')) }
      it { expect(described_class.multitenant?).to be true }
    end

    context 'when HYKU_MULTITENANT is "false"' do
      before { stub_const('ENV', ENV.to_h.merge('HYKU_MULTITENANT' => 'false')) }
      it { expect(described_class.multitenant?).to be false }
    end

    context 'when HYKU_MULTITENANT is absent' do
      before { stub_const('ENV', ENV.to_h.except('HYKU_MULTITENANT')) }
      it 'defaults to false' do
        expect(described_class.multitenant?).to be false
      end
    end
  end

  describe '.single_tenant?' do
    context 'when HYKU_MULTITENANT is "false"' do
      before { stub_const('ENV', ENV.to_h.merge('HYKU_MULTITENANT' => 'false')) }
      it { expect(described_class.single_tenant?).to be true }
    end

    context 'when HYKU_MULTITENANT is "true"' do
      before { stub_const('ENV', ENV.to_h.merge('HYKU_MULTITENANT' => 'true')) }
      it { expect(described_class.single_tenant?).to be false }
    end
  end

  # @see config/application.rb
  describe '#default_bulkrax_field_mappings=' do
    around do |example|
      Hyku.instance_variable_set(:@default_bulkrax_field_mappings, nil)
      example.run
      Hyku.instance_variable_set(:@default_bulkrax_field_mappings, nil)
    end

    context 'when value is a Hash' do
      let(:value) { { hello: 'world' } }

      it 'sets @default_bulkrax_field_mappings' do
        expect { described_class.default_bulkrax_field_mappings = value }
          .to change { Hyku.instance_variable_get(:@default_bulkrax_field_mappings) }
          .from(nil)
          .to(value.with_indifferent_access)
      end
    end

    context 'when value is an ActiveSupport::HashWithIndifferentAccess' do
      let(:value) { { hello: 'world' }.with_indifferent_access }

      it 'sets @default_bulkrax_field_mappings' do
        expect { described_class.default_bulkrax_field_mappings = value }
          .to change { Hyku.instance_variable_get(:@default_bulkrax_field_mappings) }
          .from(nil)
          .to(value)
      end
    end

    context 'when value does not respond to :with_indifferent_access' do
      let(:value) { 'hello world' }

      it 'throws an error' do
        expect { described_class.default_bulkrax_field_mappings = value }
          .to raise_error(RuntimeError, 'Hyku.default_bulkrax_field_mappings must respond to #with_indifferent_access')
      end
    end
  end

  # @see config/application.rb
  describe '#default_bulkrax_field_mappings' do
    context 'when @default_bulkrax_field_mappings is present' do
      around do |example|
        Hyku.instance_variable_set(:@default_bulkrax_field_mappings, 'greetings')
        example.run
        Hyku.instance_variable_set(:@default_bulkrax_field_mappings, nil)
      end

      it 'returns @default_bulkrax_field_mappings' do
        expect(described_class.default_bulkrax_field_mappings).to eq('greetings')
      end
    end

    context 'when @default_bulkrax_field_mappings is blank' do
      around do |example|
        Hyku.instance_variable_set(:@default_bulkrax_field_mappings, nil)
        example.run
        Hyku.instance_variable_set(:@default_bulkrax_field_mappings, nil)
      end

      it 'returns the default field mappings' do
        default_bulkrax_mapping_keys = ['Bulkrax::OaiDcParser', 'Bulkrax::OaiQualifiedDcParser', 'Bulkrax::CsvParser', 'Bulkrax::BagitParser', 'Bulkrax::XmlParser']

        expect(described_class.default_bulkrax_field_mappings).to be_a(ActiveSupport::HashWithIndifferentAccess)
        expect(described_class.default_bulkrax_field_mappings.keys.sort).to eq(default_bulkrax_mapping_keys.sort)
      end

      describe 'the CSV parser mappings' do
        subject(:csv_mappings) { described_class.default_bulkrax_field_mappings['Bulkrax::CsvParser'] }

        it 'exports descriptive fields people enter' do
          %w[rights_statement alternative_title additional_information].each do |field|
            expect(csv_mappings[field]).not_to include('generated'), "#{field} is flagged generated, so exports drop it"
          end
        end

        it 'still leaves system-maintained fields out of exports' do
          %w[date_uploaded depositor admin_set_id state].each do |field|
            expect(csv_mappings.dig(field, 'generated')).to be(true), "#{field} should stay generated"
          end
        end

        it 'exports the rights statement under the rights_statement column' do
          expect(csv_mappings.dig('rights_statement', 'from').first).to eq('rights_statement')
        end

        let(:m3_properties) { YAML.safe_load_file(Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml'))['properties'] }

        it 'exports every property the default m3 profile requires' do
          required = m3_properties.select { |_key, config| config.dig('cardinality', 'minimum').to_i.positive? }
                                  .map { |key, config| config['name'] || key }

          required.each do |property|
            expect(csv_mappings).to include(property), "#{property} is required by the m3 profile but has no Bulkrax mapping"
            expect(csv_mappings[property]).not_to include('generated'), "#{property} is required by the m3 profile, so exports must keep it"
          end
        end

        it 'maps profile properties by the name they are stored under' do
          renamed_keys = m3_properties.select { |key, config| config['name'].present? && config['name'] != key }.keys
          property_keys = csv_mappings.reject { |_key, config| config['object'] }.keys

          expect(property_keys & renamed_keys).to be_empty
        end
      end
    end
  end
end
