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

  it 'shows public institutions and links to their tenants' do
    visit '/'

    expect(page).to have_content('Public Institution')
    expect(page).to have_link('Public Institution', href: %r{public\.example\.com})
    expect(page).not_to have_content('Private Institution')
  end

  it 'shows tenant administration links to a signed-in superadmin' do
    login_as create(:superadmin), scope: :user
    visit '/'

    expect(page).to have_link('Accounts')
    expect(page).to have_link('Users')
    click_link 'Logout'
    expect(page).to have_current_path('/')
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
    # Grounded in app/views/_admin_util_links.html.erb, which renders
    # 'shared/locale_picker' when available_translations.size > 1; the picker is
    # a <select> whose accessible name is 'Language' (see the sibling feature
    # spec spec/features/ui_ux_and_static_pages_spec.rb using
    # select(..., from: 'Language')).
    it 'offers a Language dropdown for choosing the display language' do
      visit '/'

      expect(page).to have_select('Language')
    end

    # Plan sub-item: "Each institution has a display of their theme logo (or a
    # placeholder if there is no logo)."
    # Not grounded: app/views/splash/index.html.erb (the admin_host root) renders
    # only the shared Hyku logo (logo-hyku.png) and three product-feature
    # columns -- it does not iterate tenant accounts or render per-institution
    # theme logos. Any per-institution logo/placeholder listing is a downstream
    # (knapsack) customization not present in this repository.
    it 'shows each institution with its theme logo or a placeholder' do
      skip('Base Hyku splash#index (app/views/splash/index.html.erb) renders the ' \
           'shared Hyku logo and product-feature columns, not a per-tenant ' \
           'institution list with theme logos; no such view exists in this repo.')
    end

    # Plan sub-item: "Selecting a language only sets the language for the current
    # site, not for each of the individual tenants."
    # Requires the locale picker to auto-submit (JS) and cross-host session
    # isolation between the admin host and a tenant host, neither of which is
    # exercisable in a rack_test (non-JS) feature spec.
    it 'keeps a chosen language scoped to the current site and not individual tenants' do
      skip('Cross-tenant locale isolation needs a JS driver to submit the picker ' \
           'and separate per-host sessions; not feasible in a rack_test feature spec.')
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
    # (signed-in administrator). Same locale_picker in _admin_util_links.
    it 'offers a Language dropdown to a signed-in administrator' do
      visit '/'

      expect(page).to have_select('Language')
    end
  end
end

# ## Global Index / Institution List Page
# [Back to TOC](#table-of-contents)

# ![image4](https://github.com/samvera/hyku/assets/19597776/4e6c6681-39e3-491a-ab7d-64f995d775b4)

# ### As a non-signed in user:

# - [ ] I can see a list of each institution
#   - [ ] Each institution has a display of their theme logo (or a placeholder if there is no logo)
#   - [ ] I can click on the link for each institution, which directs me to the tenant for that institution
# - [ ] I can click on the link to Administrator login (in the footer), which directs me to the Log in form
# - [ ] I can select my preferred language from the Language dropdown menu
#   - [ ] Selecting a language only sets the language for the current site, not for each of the individual tenants

# ![image39](https://github.com/samvera/hyku/assets/19597776/005910e7-8fbd-4c27-a9d4-a6cc07f34820)

# ### As a signed-in administrator:

# - [ ] I can see a list of each institution
#   - [ ] Each institution has a display of their theme logo (or a placeholder if there is no logo)
#   - [ ] I can click on the link for each institution, which directs me to the tenant for that institution
# - [ ] I can click Logout, which logs me out and directs me back to the Global Index page
# - [ ] I can select my preferred language from the Language dropdown menu
#   - [ ] Selecting a language only sets the language for the current site, not for each of the individual tenants
# - [ ] I can click on Accounts, which directs me to the Accounts page for the tenants
# - [ ] I can click on Users, which directs me to the Manage Users page for the users