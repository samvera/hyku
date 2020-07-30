# frozen_string_literal: true

RSpec.describe 'Site Roles' do
  context 'as an administrator' do
    let!(:user) { FactoryBot.create(:admin) }
    let!(:another_user) { FactoryBot.create(:user) }

    before do
      login_as(user, scope: :user)
    end

    it 'lists user roles' do
      visit site_roles_path

      expect(page).to have_css 'td', text: user.email
      expect(page).to have_css 'td', text: another_user.email
    end

    it 'updates user roles' do
      visit site_roles_path

      within "#edit_user_#{another_user.id}" do
        select 'admin', from: 'Roles'
        click_on 'Save'
      end

      expect(another_user.reload).to have_role :admin, Site.instance
    end
  end
end
