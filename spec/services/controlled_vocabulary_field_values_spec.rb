# frozen_string_literal: true

RSpec.describe ControlledVocabularyFieldValues do
  let(:values) { described_class.to_proc }
  let(:config) { Blacklight::Configuration::IndexField.new(field: 'discipline_tesim') }

  def fetch(document)
    values.call(config, document, nil)
  end

  it 'shows the label where one is indexed' do
    document = SolrDocument.new('discipline_tesim' => ['chem_1'],
                                'discipline_label_tesim' => ['Chemistry'])

    expect(fetch(document)).to eq ['Chemistry']
  end

  it 'falls back to the stored id when no label is indexed' do
    document = SolrDocument.new('discipline_tesim' => ['chem_1'])

    expect(fetch(document)).to eq ['chem_1']
  end

  it 'falls back when the label field is present but empty' do
    document = SolrDocument.new('discipline_tesim' => ['chem_1'], 'discipline_label_tesim' => [])

    expect(fetch(document)).to eq ['chem_1']
  end

  it 'is nil when the property has no value at all' do
    expect(fetch(SolrDocument.new('id' => 'x'))).to be_nil
  end

  context 'when the field links to a label facet' do
    let(:config) do
      Blacklight::Configuration::IndexField.new(field: 'education_level_tesim',
                                                link_to_facet: 'education_level_label_sim')
    end

    it 'still shows the label' do
      document = SolrDocument.new('education_level_tesim' => ['ug_1'],
                                  'education_level_label_tesim' => ['Undergraduate'])

      expect(fetch(document)).to eq ['Undergraduate']
    end
  end

  describe '.label_key' do
    it 'inserts label before the solr suffix' do
      expect(described_class.label_key('discipline_tesim')).to eq 'discipline_label_tesim'
    end

    it 'handles a facet suffix' do
      expect(described_class.label_key('resource_type_sim')).to eq 'resource_type_label_sim'
    end

    it 'leaves a key with no suffix alone' do
      expect(described_class.label_key('id')).to eq 'id'
    end
  end
end
