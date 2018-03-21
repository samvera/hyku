RSpec.describe CreateSolrCollectionJob do
  let(:account) { FactoryGirl.create(:account) }
  let(:client) { double }

  before do
    allow(Blacklight.default_index).to receive(:connection).and_return(client)
  end

  describe '#perform' do
    it 'creates a new collection for an account' do
      expect(client).to receive(:get).with('/solr/admin/collections',
                                           params: { action: 'LIST' }).and_return('collections' => [])

      expect(client).to receive(:get).with('/solr/admin/collections',
                                           params: hash_including(action: 'CREATE',
                                                                  name: account.tenant,
                                                                  'collection.configName': 'hyku'))
      described_class.perform_now(account)

      expect(account.solr_endpoint.url).to eq "#{Settings.solr.url}#{account.tenant}"
    end

    it 'is idempotent' do
      expect(client).to receive(:get).with('/solr/admin/collections',
                                           params: { action: 'LIST' }).and_return('collections' => [account.tenant])

      expect(client).not_to receive(:get).with('/solr/admin/collections', params: hash_including(action: 'CREATE'))

      described_class.perform_now(account)
    end
  end

  describe CreateSolrCollectionJob::CollectionOptions do
    describe '#to_h' do
      subject { described_class.new(data).to_h }

      let(:data) do
        {
          collection: { config_name: 'hyku', blank: '' },
          num_shards: 1,
          replication_factor: 5,
          rule: 'asdf',
          blank: ''
        }
      end

      it 'removes blank values' do
        expect(subject).not_to include(blank: '')
        expect(subject).not_to include('collection.blank': '')
      end

      it 'collapses nested hashes' do
        expect(subject).to include('collection.configName': 'hyku')
      end

      it 'camelizes key values' do
        expect(subject).to include(replicationFactor: 5)
      end
    end
  end
end
