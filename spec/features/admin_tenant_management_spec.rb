# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Tenant Management', multitenant: true do
  let(:superadmin) { create(:superadmin) }
  let(:account) do
    create(:account, name: 'Existing Institution').tap do |created_account|
      created_account.create_solr_endpoint(url: 'http://localhost:8080/solr')
      created_account.create_fcrepo_endpoint(url: 'http://localhost:8080/fcrepo')
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
    fill_in 'Short name', with: 'testtenant'
    within('.account-form') do
      click_button
    end
    expect(page).to have_content('testtenant')
    click_link 'Edit Account'
    check 'Is public'
    click_button 'Save changes'
    visit edit_proprietor_account_path(Account.find_by!(name: 'testtenant'))
    expect(page).to have_checked_field('Is public')
    visit proprietor_accounts_path
    within('tr', text: 'testtenant') do
      click_link 'Delete'
    end
    expect(page).not_to have_content('testtenant')
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

  it 'can filter/search tenants and users' do
    visit proprietor_accounts_path
    expect(page).to have_content(account.tenant)
    visit proprietor_users_path
    expect(page).to have_content(superadmin.email)
  end
end
