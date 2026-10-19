# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Global institution index', type: :feature, multitenant: true, clean: true do
  around do |example|
    original_host = Capybara.default_host
    Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
    example.run
    Capybara.default_host = original_host
  end

  let!(:public_account) { create(:account, name: 'Public Institution', cname: 'public.example.com', public_demo_tenant: true) }
  let!(:private_account) { create(:account, name: 'Private Institution', cname: 'private.example.com', public_demo_tenant: false) }

  it 'shows tenant administration links to a signed-in superadmin' do
    login_as create(:superadmin), scope: :user
    visit '/'

    expect(page).to have_link('Accounts')
    expect(page).to have_link('Users')
    # Scoped: the page renders more than one "Logout" link.
    within('#user_utility_links') { click_link 'Logout' }
    expect(page).to have_current_path('/', ignore_query: true)
    expect(page).to have_link('Administrator login')
    expect(page).not_to have_link('Accounts')
  end

  context 'as a non-signed-in visitor' do
    # Plan: "I can click on the link to Administrator login (in the footer),
    # which directs me to the Log in form."
    # Grounded in app/views/shared/_footer.html.erb: when no user is signed in
    # the footer renders link_to t('hyku.footer.admin_login') ("Administrator
    # login", config/locales/en.yml) to main_app.new_user_session_path.
    it 'offers an Administrator login link in the footer that leads to the sign-in form' do
      visit '/'

      within('footer') do
        click_link 'Administrator login'
      end

      expect(page).to have_current_path(%r{/users/sign_in})
      expect(page).to have_css('input[type="password"]')
    end

    # Plan: "I can select my preferred language from the Language dropdown menu."
    # app/views/_admin_util_links.html.erb renders 'shared/locale_picker', a dropdown of
    # links (#language-dropdown-menu), not a <select>.
    it 'offers a Language dropdown for choosing the display language' do
      visit '/'
      within('#language-dropdown-menu') do
        expect(page).to have_link('English')
        expect(page).to have_link('Español')
        click_link 'Español'
      end

      expect(page).to have_link('Inicio de sesión de administrador')
    end

    # Plan sub-item: "Selecting a language only sets the language for the current
    # site, not for each of the individual tenants."
    # Plan: "Selecting a language only sets the language for the current site, not for each
    # of the individual tenants." Hyrax keeps the language in the ?locale= param on this
    # site's links; it is not stored in a session or cookie, so it cannot reach a tenant site.
    # This checks that mechanism on the global site; no tenant site is visited.
    it "sets the language only for the current site's links and does not store it" do
      visit '/'
      within('#language-dropdown-menu') { click_link 'Español' }

      # The choice rides along on this site's links...
      expect(page).to have_link('Inicio de sesión de administrador', href: /locale=es/)

      # ...but is not stored anywhere, so a fresh request is back to the default.
      visit '/'
      expect(page).to have_link('Administrator login')
      expect(page).not_to have_link('Inicio de sesión de administrador')
    end
  end

  context 'as a signed-in superadmin' do
    before { login_as create(:superadmin), scope: :user }

    # Plan: "I can click on Accounts, which directs me to the Accounts page for
    # the tenants."
    # Grounded in app/views/_admin_util_links.html.erb: link_to
    # main_app.proprietor_accounts_path (config/routes.rb -> proprietor/accounts).
    it 'links Accounts to the tenant accounts page' do
      visit '/'
      click_link 'Accounts'

      expect(page).to have_current_path(%r{/proprietor/accounts}, ignore_query: true)
    end

    # Plan: "I can click on Users, which directs me to the Manage Users page for
    # the users."
    # Grounded in app/views/_admin_util_links.html.erb: link_to
    # main_app.proprietor_users_path (config/routes.rb -> proprietor/users).
    it 'links Users to the manage users page' do
      visit '/'
      click_link 'Users'

      expect(page).to have_current_path(%r{/proprietor/users}, ignore_query: true)
    end

    # Plan: "I can select my preferred language from the Language dropdown menu"
    # (signed-in administrator). Same locale_picker link dropdown in _admin_util_links.
    it 'offers a Language dropdown to a signed-in administrator' do
      visit '/'
      within('#language-dropdown-menu') do
        expect(page).to have_link('English')
        click_link 'Español'
      end

      # The admin utility links switch to Spanish.
      expect(page).to have_link('Cuentas')
    end

    # Plan sub-item (signed-in administrator): "Selecting a language only sets the language
    # for the current site, not for each of the individual tenants." Same check as the
    # visitor example; no tenant site is visited.
    it "sets the language only for the current site's links and does not store it" do
      visit '/'
      within('#language-dropdown-menu') { click_link 'Español' }

      expect(page).to have_link('Cuentas', href: /locale=es/)

      visit '/'
      expect(page).to have_link('Accounts')
      expect(page).not_to have_link('Cuentas')
    end
  end
end
