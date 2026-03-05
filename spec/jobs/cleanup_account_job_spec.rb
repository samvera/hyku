# frozen_string_literal: true

RSpec.describe CleanupAccountJob do
  it 'removes all endpoints when transition is enabled' do
    solr_endpoint = instance_double(SolrEndpoint)
    fcrepo_endpoint = instance_double(FcrepoEndpoint)
    redis_endpoint = instance_double(RedisEndpoint)
    account = instance_double(Account, solr_endpoint:, fcrepo_endpoint:, redis_endpoint:, tenant: 'test-tenant')

    allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
    allow(solr_endpoint).to receive(:remove!)
    allow(fcrepo_endpoint).to receive(:remove!)
    allow(redis_endpoint).to receive(:remove!)
    allow(account).to receive(:destroy)
    allow(Apartment::Tenant).to receive(:drop).with('test-tenant')

    expect(fcrepo_endpoint).to receive(:remove!)

    described_class.perform_now(account)
  end

  it 'skips Fedora cleanup when transition is disabled' do
    solr_endpoint = instance_double(SolrEndpoint)
    fcrepo_endpoint = instance_double(FcrepoEndpoint)
    redis_endpoint = instance_double(RedisEndpoint)
    account = instance_double(Account, solr_endpoint:, fcrepo_endpoint:, redis_endpoint:, tenant: 'test-tenant')

    allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(false)
    allow(solr_endpoint).to receive(:remove!)
    allow(redis_endpoint).to receive(:remove!)
    allow(account).to receive(:destroy)
    allow(Apartment::Tenant).to receive(:drop).with('test-tenant')

    expect(fcrepo_endpoint).not_to receive(:remove!)

    described_class.perform_now(account)
  end
end
