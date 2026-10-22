# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Tenant Management', multitenant: true, flexible: :either do
  let(:superadmin) { create(:superadmin) }
  let(:account) do
    create(:account, name: 'Existing Institution').tap do |created_account|
      created_account.create_solr_endpoint(url: 'http://localhost:8080/solr')
      created_account.create_fcrepo_endpoint(url: 'http://localhost:8080/fcrepo')
      # create_*_endpoint saves the endpoint but not the account's link to it.
      created_account.save!
    end
  end

  before do
    allow(Flipflop).to receive(:read_only?).and_return(false)
    allow(Account).to receive(:from_request).and_return(account)
    login_as superadmin, scope: :user
    allow(Apartment::Tenant).to receive(:switch) do |&block|
      block.call
    end
    allow_any_instance_of(Account).to receive(:find_or_schedule_jobs)
    allow_any_instance_of(Account).to receive(:switch!).and_return(true)
    account.admin_emails = [superadmin.email]
    allow(CreateAccountInlineJob).to receive(:perform_now).and_return(true)
    allow(Hyrax::AdminSetCreateService).to receive(:find_or_create_default_admin_set)
      .and_return(instance_double(Hyrax.config.admin_set_class, id: 'admin-set-id'))
  end

  around do |example|
    default_host = Capybara.default_host
    Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
    example.run
    Capybara.default_host = default_host
  end

  it 'can create, edit, and delete a tenant account' do
    visit new_proprietor_account_path
    fill_in 'Short name', with: 'oakridge'
    within('.account-form') do
      click_button
    end
    # Save lands on the new tenant's Manage Account page.
    expect(page).to have_current_path(proprietor_account_path(Account.find_by!(name: 'oakridge')), ignore_query: true)
    expect(page).to have_content('oakridge')
    click_link 'Edit Account'
    check 'Is public'
    click_button 'Save changes'
    # Save changes lands back on the Manage Account page.
    expect(page).to have_current_path(proprietor_account_path(Account.find_by!(name: 'oakridge')), ignore_query: true)
    visit edit_proprietor_account_path(Account.find_by!(name: 'oakridge'))
    expect(page).to have_checked_field('Is public')
    visit proprietor_accounts_path
    within('tr', text: 'oakridge') do
      click_link 'Delete'
    end
    expect(page).not_to have_content('oakridge')
    expect(Account.find_by(name: 'oakridge')).to be_nil
  end

  it 'can invite and remove tenant administrators' do
    create(:user, email: 'admin2@example.com')
    visit proprietor_accounts_path
    within('tr', text: account.tenant) do
      click_link 'Manage'
    end
    fill_in 'add_form_account_admin_emails', with: 'admin2@example.com'
    admin_form = find('#add_form_account_admin_emails').find(:xpath, './ancestor::form[1]')
    within(admin_form) do
      click_button 'Add Admin'
    end
    expect(page).to have_content('admin2@example.com')
    within('#current-admins-tab tr', text: 'admin2@example.com') do
      find('input[type="submit"][value="Remove Admin"]', visible: false).click
    end
    within('#current-admins-tab') do
      expect(page).not_to have_content('admin2@example.com')
    end
  end

  it 'redirects an unauthenticated visitor to the login page with a not-authorized flash' do
    logout(:user)
    visit proprietor_accounts_path
    expect(page).to have_current_path(%r{/users/sign_in})
    expect(page).to have_content('You are not authorized to access this page.')
  end

  it 'lists tenant accounts with UUID, CNAME, and Manage/Edit/Delete actions' do
    visit proprietor_accounts_path
    within('table.datatable thead') do
      expect(page).to have_content('Tenant (UUID)')
      expect(page).to have_content('CNAME')
      expect(page).to have_content('Actions')
    end
    within('tr', text: account.tenant) do
      expect(page).to have_link('Manage')
      expect(page).to have_link('Edit')
      expect(page).to have_link('Delete')
    end
  end

  it 'offers a cancel link and rejects a blank short name on the new account form' do
    visit new_proprietor_account_path
    within('.account-form') do
      click_button
    end
    expect(page).to have_content('prohibited this repository from being saved')
    expect(page).to have_field('Short name')

    click_link 'Cancel'
    expect(page).to have_current_path(proprietor_accounts_path, ignore_query: true)
  end

  it 'shows the tenant cname, edit/cancel links, and admin tabs on the manage page' do
    visit proprietor_accounts_path
    within('tr', text: account.tenant) do
      click_link 'Manage'
    end
    expect(page).to have_content(account.cname)
    expect(page).to have_content('Current Account Administrators')
    expect(page).to have_content('All Users')

    click_link 'Edit Account'
    expect(page).to have_current_path(edit_proprietor_account_path(account), ignore_query: true)

    visit proprietor_account_path(account)
    click_link 'Cancel'
    expect(page).to have_current_path(proprietor_accounts_path, ignore_query: true)
  end

  it 'renders the editable account fields and a cancel link on the edit form' do
    visit edit_proprietor_account_path(account)
    expect(page).to have_field('Is public')
    expect(page).to have_field('Tenant UUID', readonly: true)
    expect(page).to have_field('Primary Domain Name', readonly: true)
    expect(page).to have_content('Solr Endpoint')
    expect(page).to have_field('account_solr_endpoint_attributes_url', with: account.solr_endpoint.url)
    unless Hyrax.config.disable_wings
      expect(page).to have_content('Fedora Endpoint')
      expect(page).to have_field('account_fcrepo_endpoint_attributes_url', with: account.fcrepo_endpoint.url)
      expect(page).to have_field('Base Path')
    end

    click_link 'Cancel'
    expect(page).to have_current_path(proprietor_accounts_path, ignore_query: true)
  end

  # Manual Test Plan: "Global Tenant Accounts Index Page (Admin only)"
  it 'navigates from the accounts index to the Manage, Edit and Create new account pages' do
    visit proprietor_accounts_path
    within('tr', text: account.tenant) { click_link 'Edit' }
    expect(page).to have_current_path(edit_proprietor_account_path(account), ignore_query: true)
    expect(page).to have_field('Tenant UUID', with: account.tenant, readonly: true)

    visit proprietor_accounts_path
    within('tr', text: account.tenant) { click_link 'Manage' }
    expect(page).to have_current_path(proprietor_account_path(account), ignore_query: true)

    visit proprietor_accounts_path
    click_link 'Create new account'
    expect(page).to have_current_path(new_proprietor_account_path, ignore_query: true)
    expect(page).to have_field('Short name')
  end

  # Manual Test Plan: "Global Tenant Accounts Index Page" - filtering with the DataTables search bar.
  it 'filters the tenant accounts with the search bar', js: true do
    other = create(:account, name: 'Zanzibar Polytechnic')
    visit proprietor_accounts_path
    expect(page).to have_css('tbody tr', text: account.tenant)
    expect(page).to have_css('tbody tr', text: other.tenant)

    find('.dataTables_filter input[type="search"]').fill_in(with: 'zanzibar-polytechnic')

    expect(page).to have_css('tbody tr', text: other.cname)
    expect(page).not_to have_css('tbody tr', text: account.tenant)
  end

  # Manual Test Plan: "Global Tenant Account New Page (Admin only)" - invalid (not just blank) input.
  it 'rejects a short name that is already in use' do
    visit new_proprietor_account_path
    fill_in 'Short name', with: account.name
    expect do
      within('.account-form') { click_button }
    end.not_to change(Account, :count)

    expect(page).to have_content('prohibited this repository from being saved')
    expect(page).to have_content('has already been taken')
    expect(page).to have_field('Short name', with: account.name)
  end

  # Remove this comment and the `pending` call to re-enable this test when issue #3421 is fixed.
  # KNOWN APPLICATION ISSUE: a short name ending in "." raises ArgumentError (500) instead of a
  # validation error. Fix goes in app/models/account.rb (before_validation calling AccountCname.default_cname).
  it 'rejects a short name with a trailing dot' do
    pending('Account.default_cname raises ArgumentError for a trailing dot instead of failing validation')
    visit new_proprietor_account_path
    fill_in 'Short name', with: 'trailingdot.'
    within('.account-form') { click_button }

    expect(page).to have_content('prohibited this repository from being saved')
    expect(Account.where(name: 'trailingdot.')).to be_empty
  end

  # Manual Test Plan: "Global Tenant Account Manage Page (Admin only)"
  describe 'inviting administrators on the Manage page' do
    def submit_invite(email)
      visit proprietor_account_path(account)
      fill_in 'add_form_account_admin_emails', with: email
      find('#add_form_account_admin_emails').find(:xpath, './ancestor::form[1]').click_button('Add')
    end

    # The input is a plain text field and AccountsController#update accepts any list, so a blank or
    # malformed entry is not reported as an error; it simply adds nobody.
    it 'adds nobody for a blank or malformed email' do
      submit_invite('')
      expect(page).to have_content('Account was successfully updated.')
      expect(account.admin_emails).to contain_exactly(superadmin.email)

      submit_invite('not-an-email')
      expect(page).to have_content('Account was successfully updated.')
      expect(account.admin_emails).to contain_exactly(superadmin.email)
      expect(User.find_by(email: 'not-an-email')).to be_nil
      within('#current-admins-tab') { expect(page).not_to have_content('not-an-email') }
    end

    it 'invites an email that has no user yet and lists it as a current administrator' do
      expect(User.find_by(email: 'invited.admin@example.com')).to be_nil

      submit_invite('invited.admin@example.com')

      expect(page).to have_current_path(proprietor_account_path(account), ignore_query: true)
      within('#current-admins-tab') do
        expect(page).to have_css('tr', text: 'invited.admin@example.com')
        expect(page).to have_css('tr', text: superadmin.email)
      end
      invited = User.find_by!(email: 'invited.admin@example.com')
      expect(invited.invitation_sent_at).to be_present
      expect(account.admin_emails).to contain_exactly(superadmin.email, 'invited.admin@example.com')
    end
  end

  it 'lists every user under All Users and its Add makes that user an administrator' do
    candidate = create(:user, email: 'aaa.candidate@example.com')
    bystander = create(:user, email: 'aab.bystander@example.com')
    visit proprietor_account_path(account)

    within('#current-admins-tab') { expect(page).not_to have_content(candidate.email) }
    within('#all-users-tab') do
      expect(page).to have_css('tr', text: candidate.email)
      expect(page).to have_css('tr', text: bystander.email)
      expect(page).to have_css('tr', text: superadmin.email)
      # Users who are already administrators get no Add button.
      within('tr', text: superadmin.email) { expect(page).not_to have_button('Add') }
      within('tr', text: candidate.email) { click_button 'Add' }
    end

    expect(page).to have_current_path(proprietor_account_path(account), ignore_query: true)
    within('#current-admins-tab') do
      expect(page).to have_css('tr', text: candidate.email)
      expect(page).not_to have_content(bystander.email)
    end
    expect(account.admin_emails).to contain_exactly(superadmin.email, candidate.email)
  end

  # Manual Test Plan: "Global Tenant Account Edit Page (Admin only)"
  # The single Tenant CNAME input became a read-only "Primary Domain Name" plus editable Domain Names.
  # Potential duplicate: spec/features/accounts_spec.rb:43 (edit form saves endpoint URLs)
  # Remove this comment and the `pending` call to re-enable this test when issue #3422 is fixed.
  # KNOWN APPLICATION ISSUE: saving the edit form raises NoMethodError when an array setting such
  # as email_format has values: the inputs are not array-named, so a String is posted. Fix goes in
  # app/views/shared/_settings.html.erb (see its FIXME) or AccountSettings#validate_email_format.
  it 'shows the account values and saves edits back to the Manage Account page' do
    pending("array settings (email_format) are posted as a String, so validation raises NoMethodError")
    original_cname = account.cname
    visit edit_proprietor_account_path(account)
    expect(page).to have_field('Primary Domain Name', with: original_cname, readonly: true)

    expect(page).to have_field('account_domain_names_attributes_0_cname', with: original_cname)
    fill_in 'account_domain_names_attributes_0_cname', with: 'renamed-institution.example.com'
    fill_in 'account_solr_endpoint_attributes_url', with: 'http://example.com/renamed-solr/'
    click_button 'Save changes'

    expect(page).to have_current_path(proprietor_account_path(account), ignore_query: true)
    expect(page).to have_content('Account was successfully updated.')
    account.reload
    expect(account.domain_names.pluck(:cname)).to include('renamed-institution.example.com')
    expect(account.domain_names.pluck(:cname)).not_to include(original_cname)
    expect(account.solr_endpoint.url).to eq('http://example.com/renamed-solr/')
  end
end
