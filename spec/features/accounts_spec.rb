# frozen_string_literal: true

# NOTE: If want to run spec in browser, you have to set "js: true"
RSpec.describe 'Accounts administration', multitenant: true do
  context 'as an superadmin' do
    let(:user) { FactoryBot.create(:superadmin) }
    let(:account) do
      FactoryBot.create(:account).tap do |acc|
        acc.create_solr_endpoint(url: 'http://localhost:8080/solr')
        acc.create_fcrepo_endpoint(url: 'http://localhost:8080/fcrepo')
      end
    end

    before do
      login_as(user, scope: :user)
      allow(Apartment::Tenant).to receive(:switch).with(account.tenant) do |&block|
        block.call
      end
      allow_any_instance_of(Account).to receive(:find_or_schedule_jobs)
    end

    around do |example|
      default_host = Capybara.default_host
      Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
      example.run
      Capybara.default_host = default_host
    end

    it 'changes the associated cname' do
      pending "adjust for domain names instead of single cname"
      visit edit_proprietor_account_path(account)

      fill_in 'Tenant CNAME', with: 'example.com'

      click_on 'Save'

      account.reload

      expect(account.cname).to eq 'example.com'
    end

    it 'changes the account service endpoints' do
      visit edit_proprietor_account_path(account)

      fill_in 'account_solr_endpoint_attributes_url', with: 'http://example.com/solr/'
      fill_in 'account_fcrepo_endpoint_attributes_url', with: 'http://example.com/fcrepo'
      fill_in 'account_fcrepo_endpoint_attributes_base_path', with: '/dev'

      click_on 'Save'

      account.reload

      expect(account.solr_endpoint.url).to eq 'http://example.com/solr/'
      expect(account.fcrepo_endpoint.url).to eq 'http://example.com/fcrepo'
      expect(account.fcrepo_endpoint.base_path).to eq '/dev'
    end
  end
end
