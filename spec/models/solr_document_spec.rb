# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocument, type: :model do
  let(:solr_document) { described_class.new }
  let(:query_result) do
    { 'response' => { 'docs' => [
      { 'id' => '123', 'title_tesim' => ['Title 1'] },
      { 'id' => '456', 'title_tesim' => ['Title 2'] }
    ] } }
  end

  before do
    allow(Hyrax::SolrService).to receive(:post).and_return(query_result)
  end

  describe '#load_parent_docs' do
    it 'loads parent documents from Solr' do
      parent_docs = solr_document.load_parent_docs
      expect(parent_docs.first).to be_a SolrDocument
      expect(parent_docs.size).to eq 2
      expect(parent_docs.first.id).to eq '123'
    end
  end

  describe '#query' do
    it 'queries Solr with provided parameters' do
      result = solr_document.query("some_query", rows: 2)
      expect(result).to be_an Array
      expect(result.size).to eq 2
      expect(result.map { |r| r['id'] }).to eq ["123", "456"]
    end

    context 'when Solr response does not contain docs' do
      let(:query_result) { { 'response' => {} } }

      it 'returns an empty array' do
        result = solr_document.query("some_query", rows: 2)
        expect(result).to eq([])
      end
    end
  end

  describe '#to_semantic_values' do
    subject { solr_document.to_semantic_values }
    let(:solr_document) { SolrDocument.new(attributes) }
    let(:attributes) do
      { id: '123',
        has_model_ssim: ['GenericWork'],
        account_cname_tesim: ['test.hyku'],
        thumbnail_path_ss: '/thumbnail.png',
        title_tesim: ['A Title'],
        description_tesim: ['A description'],
        abstract_tesim: ['An abstract'] }
    end

    it 'includes show page and thumbnail urls in identifier' do
      expect(subject[:identifier]).to include('https://test.hyku/concern/generic_works/123')
      expect(subject[:identifier]).to include('https://test.hyku/thumbnail.png')
    end

    shared_examples_for 'maps properties to dc terms' do
      it "uses the works' schema match properties to dc terms" do
        klass_name = GenericWorkResource
        expect(solr_document.hydra_model).to eq klass_name

        schema_key = klass_name.schema.keys.find { |k| k.name == :abstract }
        expect(schema_key.meta.dig('mappings', 'simple_dc_pmh')).to eq 'dc:description'

        schema_key = klass_name.schema.keys.find { |k| k.name == :description }
        expect(schema_key.meta.dig('mappings', 'simple_dc_pmh')).to eq 'dc:description'

        expect(subject[:description]).to include('A description')
        expect(subject[:description]).to include('An abstract')
      end
    end

    context 'when not using flexible metadata' do
      it_behaves_like 'maps properties to dc terms'
    end

    context 'when using flexible metadata' do
      let(:profile_file_path) { Rails.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml') }
      let(:profile_data) { YAML.load_file(profile_file_path) }
      around do |example|
        original_value = Hyrax.config.flexible
        Hyrax.config.flexible = true
        Hyrax::FlexibleSchema.create(profile: profile_data)
        example.run
        Hyrax.config.flexible = original_value
      end

      it_behaves_like 'maps properties to dc terms'
    end
  end
end
