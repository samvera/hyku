# frozen_string_literal: true

RSpec.describe Hyku::PerThread, 'lookup authorities' do
  let(:account_a) { FactoryBot.build(:sign_up_account) }
  let(:account_b) { FactoryBot.build(:sign_up_account) }

  before do
    account_a.settings.merge!('geonames_username' => 'geo-a', 'discogs_user_token' => 'discogs-a')
    account_b.settings.merge!('geonames_username' => 'geo-b', 'discogs_user_token' => 'discogs-b')
    [account_a, account_b].each { |account| CreateAccount.new(account, []).save }
  end

  after { Apartment::Tenant.switch!(Apartment.default_tenant) }

  # A thread's DB connection can't see rows inside the main thread's open transaction.
  it "keeps each tenant's GeoNames username and Discogs token", truncation: true do
    results = results_per_tenant([account_a, account_b]) do
      [Qa::Authorities::Geonames.username, Qa::Authorities::Discogs::GenericAuthority.discogs_user_token]
    end

    expect(results).to eq(account_a => [%w[geo-a discogs-a]], account_b => [%w[geo-b discogs-b]])
  end
end
