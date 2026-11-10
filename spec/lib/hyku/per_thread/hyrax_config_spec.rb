# frozen_string_literal: true

RSpec.describe Hyku::PerThread, 'Hyrax.config' do
  let(:account_a) { FactoryBot.build(:sign_up_account) }
  let(:account_b) { FactoryBot.build(:sign_up_account) }

  before do
    account_a.settings.merge!('contact_email' => 'a@tenant-a.example', 'allow_downloads' => 'true', 'file_size_limit' => '1000', 'solr_rows_per_request' => '11', 'solr_max_results' => '111')
    account_b.settings.merge!('contact_email' => 'b@tenant-b.example', 'allow_downloads' => 'false', 'file_size_limit' => '2000', 'solr_rows_per_request' => '22', 'solr_max_results' => '222')
    [account_a, account_b].each { |account| CreateAccount.new(account, []).save }
  end

  after { Apartment::Tenant.switch!(Apartment.default_tenant) }

  # A thread's DB connection can't see rows inside the main thread's open transaction.
  it "keeps each tenant's Hyrax settings", truncation: true do
    results = results_per_tenant([account_a, account_b]) do
      [Hyrax.config.contact_email, Hyrax.config.display_media_download_link?, Hyrax.config.uploader[:maxFileSize], Hyrax.config.solr_rows_per_request,
       Hyrax.config.solr_max_results]
    end

    expect(results).to eq(account_a => [['a@tenant-a.example', true, 1000, 11, 111]], account_b => [['b@tenant-b.example', false, 2000, 22, 222]])
  end
end
