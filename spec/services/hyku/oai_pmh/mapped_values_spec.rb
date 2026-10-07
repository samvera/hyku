# frozen_string_literal: true

RSpec.describe Hyku::OaiPmh::MappedValues do
  subject(:read) do
    [].tap { |out| described_class.new(document, mappings, title_mapping: 'title-mapping').each { |*pair| out << pair } }
  end

  let(:document) do
    SolrDocument.new(
      'id' => 'abc123',
      'title_tesim' => ['A Title'],
      'creator_sim' => ['Smith, Jo'],
      'creator_tesim' => ['Smith, Jo'],
      'license_tesim' => ['http://creativecommons.org/licenses/by/3.0/us/'],
      'license_label_tesim' => ['Attribution 3.0 United States']
    )
  end
  let(:mappings) { [] }

  def stored_by_mapping
    read.to_h { |mapping, values| [mapping, values.map(&:stored)] }
  end

  it 'reads title under the title mapping when no mapping covers it' do
    expect(stored_by_mapping).to eq('title-mapping' => ['A Title'])
  end

  context 'when a mapping covers title' do
    let(:mappings) { [{ property: 'title', mapping: 'profile-title', index_keys: ['title_tesim'] }] }

    it 'reads title only under that mapping' do
      expect(stored_by_mapping).to eq('profile-title' => ['A Title'])
    end
  end

  context 'with properties that share an index field and a mapping' do
    let(:mappings) do
      %w[creator creator_hidden].map { |property| { property:, mapping: 'name', index_keys: %w[creator_sim creator_tesim] } }
    end

    it 'reads the values once' do
      expect(stored_by_mapping['name']).to eq ['Smith, Jo']
      expect(read.count { |mapping, _| mapping == 'name' }).to eq 1
    end
  end

  context 'with a controlled value' do
    let(:mappings) { [{ property: 'license', mapping: 'rights', index_keys: ['license_tesim'] }] }

    it 'pairs the stored URI with its indexed label' do
      value = read.to_h['rights'].first

      expect(value).to have_attributes(stored: 'http://creativecommons.org/licenses/by/3.0/us/',
                                       label: 'Attribution 3.0 United States')
      expect(value).to be_controlled
    end
  end

  context 'with a value whose field has no label field' do
    let(:mappings) { [{ property: 'creator', mapping: 'name', index_keys: ['creator_tesim'] }] }

    it 'is not controlled' do
      expect(read.to_h['name'].first).to have_attributes(label: nil, controlled?: false)
    end
  end
end
