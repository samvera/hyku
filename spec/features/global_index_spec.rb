# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Global institution index', type: :feature, multitenant: true, clean: true do
  around do |example|
    original_host = Capybara.default_host
    Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
    example.run
    Capybara.default_host = original_host
  end

  context 'as a non-signed-in visitor' do
    # Plan: "I can click on the link to Administrator login (in the footer),
    # which directs me to the Log in form."
    it 'offers an Administrator login link in the footer that leads to the sign-in form' do
      visit '/'

      within('footer') do
        click_link 'Administrator login'
      end

      expect(page).to have_current_path(%r{/users/sign_in})
      expect(page).to have_css('input[type="password"]')
    end

    # Plan: "I can select my preferred language from the Language dropdown menu."
    # Hyrax keeps the choice in the ?locale= param on this site's links, not in the session.
    it 'switches to the chosen language via ?locale= links without storing it' do
      visit '/'
      within('#language-dropdown-menu') do
        expect(page).to have_link('English')
        click_link 'Español'
      end

      expect(page).to have_link('Inicio de sesión de administrador', href: /locale=es/)

      visit '/'
      expect(page).to have_link('Administrator login')
      expect(page).not_to have_link('Inicio de sesión de administrador')
    end
  end

  context 'as a signed-in superadmin' do
    before { login_as create(:superadmin), scope: :user }

    it 'logs out and hides the admin links' do
      visit '/'
      expect(page).to have_link('Accounts')
      within('#user_utility_links') { click_link 'Logout' }

      expect(page).to have_current_path('/', ignore_query: true)
      expect(page).to have_link('Administrator login')
      expect(page).not_to have_link('Accounts')
    end

    # Plan: "I can click on Users, which directs me to the Manage Users page for
    # the users."
    it 'links Users to the manage users page' do
      visit '/'
      click_link 'Users'

      expect(page).to have_current_path(%r{/proprietor/users}, ignore_query: true)
    end

    it 'switches the admin links to the chosen language via ?locale= links without storing it' do
      visit '/'
      within('#language-dropdown-menu') { click_link 'Español' }

      expect(page).to have_link('Cuentas', href: /locale=es/)

      visit '/'
      expect(page).to have_link('Accounts')
      expect(page).not_to have_link('Cuentas')
    end
  end
end
