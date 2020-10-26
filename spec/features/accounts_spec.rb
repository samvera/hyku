# frozen_string_literal: true

RSpec.describe 'Accounts administration', type: :feature, js: true, multitenant: true do
  context 'as an superadmin' do
    let(:user) { FactoryBot.create(:superadmin) }
    let(:solr_endpoint) { FactoryBot.create(:solr_endpoint, options: { url: 'http://localhost:8080/solr' }) }
    let(:fcrepo_endpoint) { FactoryBot.create(:fcrepo_endpoint, options: { url: 'http://localhost:8080/fcrepo' }) }
    # let(:account) { FactoryBot.create(:account, solr_endpoint: solr_endpoint, fcrepo_endpoint: fcrepo_endpoint)}
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
    end

    after(:each) do
      # customize based on which type of logs you want displayed
      log_types = page.driver.browser.manage.logs.available_types
      log_types.each do |t|
        puts t.to_s + ": " + page.driver.browser.manage.logs.get(t).join("\n")
      end
    end

    around do |example|
      original_host = ENV['HOST']
      ENV['HOST'] = 'web'
      default_host = Capybara.default_host
      Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
      puts "+++++++++++++++++++++++ #{Capybara.default_host}"
      # Capybara.default_host = "http://#{Account.admin_host}"
      example.run
      Capybara.default_host = default_host
      ENV['HOST']=original_host
    end

    it 'changes the associated cname' do
      login_as user
      puts "-----------------------"
      puts account.inspect
      puts edit_proprietor_account_path(account)
      puts edit_proprietor_account_url(account)
      puts "-----------------------"

      visit edit_proprietor_account_url(account)
      fill_in 'Tenant CNAME', with: 'example.com'

      click_on 'Save'

      account.reload

      expect(account.cname).to eq 'example.com'
    end

    it 'changes the account service endpoints' do
      visit edit_proprietor_account_path(account)

      fill_in 'account_solr_endpoint_attributes_url', with: 'http://example.com/solr/'
      fill_in 'account_fcrepo_endpoint_attributes_url', with: 'http://example.com/fcrepo'
      page.find('#account_fcrepo_endpoint_attributes_base_path').fill_in(with: 'dev')
      # TODO(bess@2020.10.21) This spec as written in hyku fails in local development with the error
      #      Failure/Error: page.find('#account_fcrepo_endpoint_attributes_base_path').fill_in(with: '/dev')
      #       Selenium::WebDriver::Error::WebDriverError:
      #       You are trying to work with something that isn't a file.
      # Filling in a different string seems to make the spec pass, and it still seems to test important functionality,
      # but I'd like to go back and understand why this is happening.
      # fill_in 'account_fcrepo_endpoint_attributes_base_path', with: '/dev'

      click_on 'Save'

      account.reload
      expect(account.solr_endpoint.url).to eq 'http://example.com/solr/'
      expect(account.fcrepo_endpoint.url).to eq 'http://example.com/fcrepo'
      expect(account.fcrepo_endpoint.base_path).to eq 'dev'
    end
  end
end
