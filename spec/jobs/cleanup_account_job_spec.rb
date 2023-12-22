# frozen_string_literal: true

RSpec.describe CleanupAccountJob do
  let!(:account) do
    FactoryBot.create(:account).tap do |acc|
      acc.create_solr_endpoint(collection: 'x')
      acc.create_fcrepo_endpoint(base_path: '/x')
      acc.create_redis_endpoint(namespace: 'x')
    end
  end

  before do
    allow(account.solr_endpoint).to receive(:remove!)
    allow(account.fcrepo_endpoint).to receive(:remove!)
    allow(account.redis_endpoint).to receive(:remove!)
    allow(Apartment::Tenant).to receive(:drop).with(account.tenant)
  end

  it 'destroys the solr collection' do
    expect(account.solr_endpoint).to receive(:remove!)
    described_class.perform_now(account)
  end

  it 'destroys the fcrepo collection' do
    expect(account.fcrepo_endpoint).to receive(:remove!)
    described_class.perform_now(account)
  end

  it 'deletes all entries in the redis namespace' do
    expect(account.redis_endpoint).to receive(:remove!)
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
