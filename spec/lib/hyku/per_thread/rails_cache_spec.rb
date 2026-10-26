# frozen_string_literal: true

RSpec.describe Hyku::PerThread, 'Rails cache' do
  let(:account_a) { FactoryBot.build(:sign_up_account) }
  let(:account_b) { FactoryBot.build(:sign_up_account) }

  before do
    account_a.settings['cache_api'] = 'true'
    account_b.settings['cache_api'] = 'false'
    [account_a, account_b].each { |account| CreateAccount.new(account, []).save }
  end

  after { Apartment::Tenant.switch!(Apartment.default_tenant) }

  # A thread's DB connection can't see rows inside the main thread's open transaction.
  it "keeps each tenant's cache settings", truncation: true do
    results = results_per_tenant([account_a, account_b]) do
      [ActionController::Base.new.perform_caching, ActionController::Base.perform_caching,
       Rails.application.config.cache_store.first, Rails.cache.class]
    end

    expect(results).to eq(account_a => [[true, true, :redis_cache_store, ActiveSupport::Cache::RedisCacheStore]], account_b => [[false, false, :file_store, ActiveSupport::Cache::FileStore]])
  end
end
