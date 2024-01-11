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
end
