# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin User Management', multitenant: true do
  let(:superadmin) { create(:superadmin, email: 'proprietor-superadmin@example.com') }
  let!(:user) { create(:user, email: 'user1@example.com') }
  let(:account) do
    create(:account, name: 'Existing Institution').tap do |created_account|
      created_account.create_solr_endpoint(url: 'http://localhost:8080/solr')
      created_account.create_fcrepo_endpoint(url: 'http://localhost:8080/fcrepo')
    end
  end

  before do
    login_as superadmin, scope: :user
    allow(Apartment::Tenant).to receive(:switch) { |&block| block.call }
    allow_any_instance_of(Account).to receive(:find_or_schedule_jobs)
    allow_any_instance_of(Account).to receive(:switch!).and_return(true)
  end

  around do |example|
    default_host = Capybara.default_host
    Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
    example.run
    Capybara.default_host = default_host
  end

  it 'can create, edit, delete, and impersonate users' do
    visit proprietor_users_path
    click_link 'Create New'
    fill_in 'Email', with: 'newuser@example.com'
    fill_in 'Display Name', with: 'New User'
    fill_in 'Password', with: 'password123'
    within('.user-form') { click_button }
    expect(page).to have_content('newuser@example.com')
    click_link 'Edit', match: :first
    fill_in 'Display Name', with: 'Updated User'
    within('.user-form') { click_button }
    expect(page).to have_content('Updated User')
    visit proprietor_users_path
    within('tr', text: 'newuser@example.com') do
      click_link 'Delete'
    end
    expect(page).not_to have_content('newuser@example.com')
  end

  it 'can assign and remove superadmin role' do
    visit edit_proprietor_user_path(user)
    check 'Superadmin?'
    within('.user-form') { click_button }
    visit edit_proprietor_user_path(user)
    expect(page).to have_checked_field('Superadmin?')
    uncheck 'Superadmin?'
    within('.user-form') { click_button }
    visit edit_proprietor_user_path(user)
    expect(page).to have_unchecked_field('Superadmin?')
  end

  it 'can filter/search users' do
    visit proprietor_users_path
    expect(page).to have_content(user.email)
  end
end
