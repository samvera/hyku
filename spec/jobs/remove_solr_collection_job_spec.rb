# frozen_string_literal: true

RSpec.describe RemoveSolrCollectionJob do
  let(:collection) { 'x' }
  let(:connection_options) { double }
  let(:connection) { double }

  before do
    # Stub connection_options to respond with itself when without('adapter') called
    allow(connection_options).to receive(:without).with('adapter').and_return(connection_options)
  end

  context 'in multi-tenant mode (SolrCloud)', :multitenant do
    it 'destroys the solr collection' do
      expect(RSolr).to receive(:connect).with(connection_options).and_return(connection)
      expect(connection).to receive(:get).with('/solr/admin/collections',
                                               params: { action: 'DELETE', name: 'x' })
      described_class.perform_now(collection, connection_options)
    end
  end

  context 'in single-tenant mode (standalone Solr)', :singletenant do
    it 'does not call the Solr Collections API' do
      expect(RSolr).not_to receive(:connect)
      described_class.perform_now(collection, connection_options)
    end
  end
end
