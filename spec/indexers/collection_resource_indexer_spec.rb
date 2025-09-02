# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
require 'rails_helper'
require 'hyrax/specs/shared_specs/indexers'

RSpec.describe CollectionResourceIndexer do
  let(:indexer_class) { described_class }
  let(:resource)      { CollectionResource.new }

  it_behaves_like 'a Hyrax::Resource indexer'

  describe 'hide_from_catalog_search indexing' do
    let(:indexer) { described_class.new(resource: resource) }
    let(:document) { indexer.to_solr }

    context 'when hide_from_catalog_search is true' do
      before { resource.hide_from_catalog_search = true }

      it 'indexes hide_from_catalog_search_bsi as true' do
        expect(document['hide_from_catalog_search_bsi']).to be true
      end

      it 'indexes hide_from_catalog_search_tesim as true' do
        expect(document['hide_from_catalog_search_tesim']).to eq true
      end
    end

    context 'when hide_from_catalog_search is false' do
      before { resource.hide_from_catalog_search = false }

      it 'indexes hide_from_catalog_search_bsi as false' do
        expect(document['hide_from_catalog_search_bsi']).to be false
      end

      it 'indexes hide_from_catalog_search_tesim as false' do
        expect(document['hide_from_catalog_search_tesim']).to eq false
      end
    end

    context 'when hide_from_catalog_search is not set' do
      it 'indexes hide_from_catalog_search_bsi as nil (default)' do
        expect(document['hide_from_catalog_search_bsi']).to be nil
      end

      it 'indexes hide_from_catalog_search_tesim as nil (default)' do
        expect(document['hide_from_catalog_search_tesim']).to eq nil
      end
    end
  end
end
