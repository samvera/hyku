RSpec.describe CleanupAccountJob do
  let!(:account) do
    FactoryBot.create(:account).tap do |acc|
      acc.create_solr_endpoint(collection: 'x')
      acc.create_fcrepo_endpoint(base_path: '/x')
      acc.create_redis_endpoint(namespace: 'x')
    end
  end

  before do
    allow(RemoveSolrCollectionJob).to receive(:perform_later)
    allow(account.fcrepo_endpoint).to receive(:switch!)
    allow(ActiveFedora.fedora.connection).to receive(:delete)
    allow(Apartment::Tenant).to receive(:drop).with(account.tenant)
  end

  it 'destroys the solr collection' do
    expect(RemoveSolrCollectionJob).to receive(:perform_later).with('x', hash_including('url'))
    expect(account.solr_endpoint).to receive(:destroy)
    described_class.perform_now(account)
  end

  it 'destroys the fcrepo collection' do
    expect(ActiveFedora.fedora.connection).to receive(:delete).with('x')
    expect(account.fcrepo_endpoint).to receive(:destroy)
    described_class.perform_now(account)
  end

  it 'deletes all entries in the redis namespace' do
    allow(Redis.current).to receive(:keys).and_return(["x:events:x1", "x:events:x2"])
    allow(Hyrax::RedisEventStore).to receive(:instance).and_return(
      Redis::Namespace.new(account.redis_endpoint.namespace, redis: Redis.current)
    )
    expect(Hyrax::RedisEventStore.instance.namespace).to eq('x')
    expect(Hyrax::RedisEventStore.instance.keys).to eq(["events:x1", "events:x2"])
    expect(Hyrax::RedisEventStore.instance).to receive(:del).with('events:x1', 'events:x2')
    expect(account.redis_endpoint).to receive(:destroy)
    described_class.perform_now(account)
  end

  it 'destroys the tenant database' do
    expect(Apartment::Tenant).to receive(:drop).with(account.tenant)

    described_class.perform_now(account)
  end

  it 'destroys the account' do
    expect do
      described_class.perform_now(account)
    end.to change(Account, :count).by(-1)
  end
end
