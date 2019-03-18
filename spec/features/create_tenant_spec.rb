require 'rails_helper'

RSpec.describe 'creating a new tenant', multitenant: true do
  include ActiveJob::TestHelper

  let(:user) { FactoryBot.create(:superadmin) }

  before do
    login_as(user, scope: :user)
  end

  around do |example|
    default_host = Capybara.default_host
    Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
    example.run
    Capybara.default_host = default_host
  end

  it 'sets up the new tenant' do
    visit '/'
    click_link 'Get Started'

    fill_in 'Short name', with: 'some-random-name'
    click_on 'Save'

    account = Account.find_by(cname: "some-random-name.#{Account.admin_host}")
    expect(account.solr_endpoint.url).not_to be_blank
    expect(account.fcrepo_endpoint.base_path).not_to be_blank
    expect(account.redis_endpoint.namespace).not_to be_blank

    account.switch do
      expect(AdminSet.count).to eq 1
    end
  end
end
