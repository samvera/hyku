# frozen_string_literal: true

require 'rails_helper'
RSpec.describe "The Manage Users table", type: :feature, js: true, clean: true do
  include Warden::Test::Helpers

  context 'as an admin user' do
    let(:admin_role) { create(:role, :admin) }
    let(:collection_manager_role) { create(:role, :collection_manager) }
    let(:user_manager_role) { create(:role, :user_manager) }

    let!(:admin_group) { create(:group, humanized_name: 'Rockets', member_users: [admin], roles: [admin_role.name]) }
    let!(:user_group) do
      create(
        :group,
        humanized_name: 'Trains',
        member_users: [user], roles: [user_manager_role.name]
      )
    end

    let(:admin) { create(:admin) }
    let(:user) { create(:user) }

    before do
      user.add_role(collection_manager_role.name, Site.instance)
      login_as admin
      visit '/admin/users'
    end

    it "lists each user's associated groups' humanized names" do
      expect(page).to have_content('Manage Users')
      expect(page).to have_css 'th', text: 'Groups'
      expect(find("tr##{admin.email.parameterize} td.groups")).to have_text(admin_group.humanized_name)
      expect(find("tr##{user.email.parameterize} td.groups")).to have_text(user_group.humanized_name)
    end

    it "lists each user's associated direct and inherited roles" do
      expect(page).to have_content('Manage Users')
      expect(page).to have_css 'th', text: 'Group roles'
      expect(page).to have_css 'th', text: 'Site roles'
      expect(find("tr##{admin.email.parameterize} td.group-roles")).to have_text(admin_role.name.titlecase)
      expect(find("tr##{user.email.parameterize} td.group-roles")).to have_text(user_manager_role.name.titlecase)
      expect(find("tr##{user.email.parameterize} td.site-roles")).to have_text(collection_manager_role.name.titlecase)
    end

    it 'can visit Manage Users and invite users with the admin role' do
      expect(page).to have_content 'Add or Invite user via email'
      expect(
        page.has_select?(
          'user_role',
          with_options: [admin_role.name.titleize, user_manager_role.name.titleize]
        )
      ).to be true
      fill_in "Email address", with: 'user@test.com'
      select admin_role.name.titleize.to_s, from: 'user_role'
      click_on "Invite user"
      expect(page).to have_content 'An invitation email has been sent to user@test.com.'
    end
  end

  context 'as a user manager' do
    let(:user_manager) { FactoryBot.create(:user_manager) }

    before do
      FactoryBot.create(:group)
      login_as(user_manager, scope: :user)
    end

    it 'can visit Manage Users and invite users' do
      visit "/admin/users"
      fill_in "Email address", with: 'user@test.com'
      select "User Manager", from: 'user_role'
      click_on "Invite user"
      expect(page).to have_content 'An invitation email has been sent to user@test.com.'
    end

    it 'can visit Manage Users but cannot invite admin users' do
      visit '/admin/users'
      select = page.find('select#user_role').all('option').collect(&:text)
      expect(select).to contain_exactly(
        'Select a role...',
        'Work Editor',
        'Work Depositor',
        'Collection Manager',
        'Collection Editor',
        'Collection Reader',
        'User Manager',
        'User Reader'
      )
      expect(select).not_to include('Admin')
    end
  end

  context 'as a user reader' do
    let(:user_reader) { FactoryBot.create(:user_reader) }

    before do
      login_as(user_reader, scope: :user)
    end

    it 'can visit Manage Users but cannot invite users' do
      visit "/admin/users"
      expect(page).not_to have_content 'Add or Invite user via email'
      expect(page.has_select?('user_role', with_options: ['Admin', 'Collection Editor', 'User Manager'])).to be false
    end
  end
end
