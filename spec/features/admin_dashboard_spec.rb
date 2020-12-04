# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Dashboard', type: :feature, js: true, clean: true do
  context 'as an administrator' do
    let(:user) { FactoryBot.create(:admin) }
    let(:group) { FactoryBot.create(:group) }

    before do
      login_as(user, scope: :user)
    end

    it 'shows the admin page' do
      visit Hyrax::Engine.routes.url_helpers.dashboard_path
      within '.sidebar' do
        expect(page).to have_link('Activity Summary')
        expect(page).to have_link('System Status')
        expect(page).to have_link("Your activity")
        # Need to click link to open collapsed menu
        click_link "Your activity"
        expect(page).to have_link('Profile')
        expect(page).to have_link('Notifications')
        expect(page).to have_link('Transfers')
        expect(page).to have_link('Manage Proxies')
        expect(page).to have_link('Settings')
        # Need to click link to open collapsed menu
        click_link "Settings"
        expect(page).to have_link('Contact')
        expect(page).to have_link('Labels')
        expect(page).to have_link('Appearance')
        expect(page).to have_link('Collection Types')
        expect(page).to have_link('Pages')
        expect(page).to have_link('Content Blocks')
        expect(page).to have_link('Features')
        expect(page).to have_link('Available Work Types')
        expect(page).to have_link('Manage Groups')
        expect(page).to have_link('Manage Users')
        expect(page).to have_link('Reports')
        expect(page).to have_link('Workflow Roles')
      end
    end

    it 'shows the status page' do
      visit status_path
      expect(page).to have_content("Fedora\nOK")
      expect(page).to have_content("Solr\nOK")
      expect(page).to have_content("Redis\nOK")
      expect(page).to have_content("Database\nOK")
    end

    it 'displays the add-users-to-groups page without the hidden form field', js: true do
      visit admin_group_users_path(group)
      expect(page).to have_content('Add User to Group')
      expect(page).to have_selector('.js-group-user-add', visible: false)
    end
  end
end
