# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Groups', type: :feature, js: true, clean: true do
  let!(:managers_group) { FactoryBot.create(:admin_group, roles: ['admin', 'dinosaur']) }
  let!(:user) { FactoryBot.create(:admin) }
  let!(:users_group) { FactoryBot.create(:group, name: 'users') }

  context 'An admin user' do
    before do
      Hyrax::Group.find_or_create_by!(name: Ability.admin_group_name).add_members_by_id(user.id)
      login_as(user, scope: :user)
    end

    it 'cannot destroy a default group' do
      visit "/admin/groups/#{managers_group.id}/remove"
      expect(page).to have_content('Default groups cannot be destroyed')
      within(".callout-action") do
        expect(page).to have_css('a.disabled', text: 'Remove')
      end
    end

    it 'can destroy a non-default group' do
      visit "/admin/groups/#{users_group.id}/remove"

      expect(page).not_to have_content('Default groups cannot be destroyed')
      expect do
        within(".callout-action") do
          click_link 'Remove'
        end
        page.driver.browser.switch_to.alert.accept
        sleep 1
      end.to change(Hyrax::Group, :count).by(-1)
    end

    it 'cannot destroy any user in the Managers group' do
      visit "/admin/groups/#{managers_group.id}/users"
      expect(page).to have_button('Remove', disabled: true)
    end

    it 'cannot destroy an admin role in the Managers group' do
      admin_role = managers_group.roles.find_by(name: 'admin')

      visit "/admin/groups/#{managers_group.id}/roles"
      tr = find("#assigned-role-#{admin_role.id}")

      expect(tr).to have_button('Remove', disabled: true)
    end

    it 'can destroy a non-admin role in the Managers group' do
      dinosaur_role = managers_group.roles.find_by(name: 'dinosaur')

      visit "/admin/groups/#{managers_group.id}/roles"
      tr = find("#assigned-role-#{dinosaur_role.id}")

      expect(tr).to have_button('Remove', disabled: false)
      expect do
        within("#assigned-role-#{dinosaur_role.id}") do
          click_button('Remove')
        end
      end.to change(managers_group.roles, :count).by(-1)
    end
  end
end
