RSpec.describe CreateAccountFcrepoJob do
  let(:account) { FactoryGirl.create(:account) }

  it 'lets parent class handle the work' do
    expect(CreateFcrepoEndpointJob).to receive(:perform_now).with(account)
    described_class.perform_now(account)
  end
  it 'chains to next job' do
    expect(CreateDefaultAdminSetJob).to receive(:perform_later).with(account) do |acct|
      expect(acct.fcrepo_endpoint.base_path).to eq "/#{account.tenant}"
    end
    described_class.perform_now(account)
  end
end
