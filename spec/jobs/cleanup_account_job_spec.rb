# frozen_string_literal: true

RSpec.describe CleanupAccountJob do
  it 'removes the various end points and database records' do
    account = Account.new(name: 'Single Tenant', cname: 'single.tenant.default', tenant: SecureRandom.uuid, is_public: true)
    # Perform all the tenant creation stuff.
    CreateAccount.new(account, []).save
    account.reload

    expect(account.solr_endpoint).to receive(:remove!).and_call_original
    expect(account.fcrepo_endpoint).to receive(:remove!).and_call_original
    expect(account.redis_endpoint).to receive(:remove!).and_call_original
    expect(Apartment::Tenant).to receive(:drop).with(account.tenant).and_call_original
    expect do
      described_class.perform_now(account)
    end.to change(Account, :count).by(-1)
  end
end
