# frozen_string_literal: true

RSpec.describe Hyku do
  it 'has a version' do
    expect(described_class).to have_constant(:VERSION)
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
    end
  end
end
