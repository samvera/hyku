# frozen_string_literal: true

RSpec.describe "The splash page", multitenant: true do
  around do |example|
    original = ENV.fetch('HYKU_ADMIN_ONLY_TENANT_CREATION', nil)
    ENV['HYKU_ADMIN_ONLY_TENANT_CREATION'] = "true"
    default_host = Capybara.default_host
    Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
    example.run
    Capybara.default_host = default_host
    ENV['HYKU_ADMIN_ONLY_TENANT_CREATION'] = original
  end

  it "shows the page, displaying the Hyku version" do
    visit '/'
    expect(page).to have_link 'Login to get started', href: main_app.new_user_session_path(locale: 'en')

    within 'footer' do
      expect(page).to have_link 'Administrator login'
    end

    expect(page).to have_content("Hyku v#{Hyku::VERSION}")
  end
end
