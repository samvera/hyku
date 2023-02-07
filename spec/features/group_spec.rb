# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Groups', type: :feature, js: true, clean: true do
  let!(:user) { FactoryBot.create(:admin) }
  let!(:managers_group) { FactoryBot.create(:admin_group, member_users: [user]) }
  let!(:users_group) { FactoryBot.create(:group, name: 'users') }

  context 'An admin user' do
    before do
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
  end
end
