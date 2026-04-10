# frozen_string_literal: true

RSpec.describe CreateSolrCollectionJob do
  let(:account) { FactoryBot.create(:account) }
  let(:client) { double }

  describe '#perform' do
    before do
      allow(Blacklight.default_index).to receive(:connection).and_return(client)
    end
    it 'creates a new collection for an account' do
      expect(client).to receive(:get).with('/solr/admin/collections',
                                           params: { action: 'LIST' }).and_return('collections' => [])

      expect(client).to receive(:get).with('/solr/admin/collections',
                                           params: hash_including(action: 'CREATE',
                                                                  name: account.tenant,
                                                                  'collection.configName': 'hyku'))
      described_class.perform_now(account)

      expect(account.solr_endpoint.url).to eq "#{ENV.fetch('SOLR_URL')}#{account.tenant}"
    end

    it 'is idempotent' do
      expect(client).to receive(:get).with('/solr/admin/collections',
                                           params: { action: 'LIST' }).and_return('collections' => [account.tenant])

      expect(client).not_to receive(:get).with('/solr/admin/collections', params: hash_including(action: 'CREATE'))

      described_class.perform_now(account)
    end
  end

  describe '#solr_url' do
    context 'with values that need to be escaped' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:[]).with('SOLR_URL').and_return(nil)
        allow(ENV).to receive(:fetch).with('SOLR_ADMIN_USER', 'admin').and_return('my&admin')
        allow(ENV).to receive(:fetch).with('SOLR_ADMIN_PASSWORD', 'admin').and_return('5+7')
        allow(Rails.logger).to receive(:warn).and_call_original
      end

      it 'leaves the password parts as-is' do
        expect(described_class.new.send(:solr_url)).to eq('http://my&admin:5+7@solr:8983/solr/')
      end

      it 'logs a warning to rails' do
        described_class.new.send(:solr_url)
        expect(Rails.logger).to have_received(:warn).with("SOLR_ADMIN_PASSWORD contains characters that may require URL encoding. " \
                        "If you experience Solr authentication errors, URL encode the value in " \
                        "SOLR_ADMIN_PASSWORD and in SOLR_URL if it is set.")
      end
    end
    context 'with default values for user and password' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:[]).with('SOLR_URL').and_return(nil)
        allow(ENV).to receive(:fetch).with('SOLR_ADMIN_USER', 'admin').and_return('admin')
        allow(ENV).to receive(:fetch).with('SOLR_ADMIN_PASSWORD', 'admin').and_return('admin')
        allow(Rails.logger).to receive(:warn).and_call_original
      end

      it 'uses default values' do
        expect(described_class.new.send(:solr_url)).to eq('http://admin:admin@solr:8983/solr/')
      end

      it 'does not log a warning to rails' do
        described_class.new.send(:solr_url)
        expect(Rails.logger).not_to have_received(:warn)
      end
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
