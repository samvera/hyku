# frozen_string_literal: true

RSpec.describe Hyku::PerThread, 'Devise mailer sender' do
  let(:account_a) { FactoryBot.build(:sign_up_account) }
  let(:account_b) { FactoryBot.build(:sign_up_account) }

  before do
    account_a.settings['contact_email'] = 'a@tenant-a.example'
    account_b.settings['contact_email'] = 'b@tenant-b.example'
    [account_a, account_b].each { |account| CreateAccount.new(account, []).save }
  end

  after { Apartment::Tenant.switch!(Apartment.default_tenant) }

  # A thread's DB connection can't see rows inside the main thread's open transaction.
  it "keeps each tenant's mailer sender", truncation: true do
    results = results_per_tenant([account_a, account_b]) do
      Devise.mailer_sender
    end

    expect(results).to eq(account_a => ['a@tenant-a.example'], account_b => ['b@tenant-b.example'])
  end
end
