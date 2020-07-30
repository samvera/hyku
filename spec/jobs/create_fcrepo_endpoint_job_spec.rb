# frozen_string_literal: true

RSpec.describe CreateFcrepoEndpointJob do
  let(:account) { FactoryBot.create(:account) }

  it 'sets the base path configuration for fcrepo' do
    described_class.perform_now(account)

    expect(account.fcrepo_endpoint.base_path).to eq "/#{account.tenant}"
  end
end
