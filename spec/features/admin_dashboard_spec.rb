RSpec.describe 'Admin Dashboard', type: :feature do
  context 'as an administrator' do
    let(:user) { FactoryGirl.create(:admin) }
    let(:group) { FactoryGirl.create(:group) }

    before do
      login_as(user, scope: :user)
    end

    it 'shows the admin page' do
      visit Hyrax::Engine.routes.url_helpers.dashboard_path
      within '.sidebar' do
        expect(page).to have_link('Activity summary')
        expect(page).to have_link('Profile')
        expect(page).to have_link('Notifications')
        expect(page).to have_link('Transfers')
        expect(page).to have_link('Labels')
        expect(page).to have_link('Appearance')
        expect(page).to have_link('Content Blocks')
        expect(page).to have_link('Technical')
        expect(page).to have_link('Manage groups')
        expect(page).to have_link('Manage users')
        expect(page).to have_link('Reports')
      end
    end

    it 'shows the status page' do
      visit status_path
      expect(page).to have_content('Fedora OK')
      expect(page).to have_content('Solr OK')
      expect(page).to have_content('Redis OK')
      expect(page).to have_content('Database OK')
    end

    it 'displays the add-users-to-groups page without the hidden form field', js: true do
      visit admin_group_users_path(group)
      expect(page).to have_content('Add User to Group')
      expect(page).to have_selector('.js-group-user-add', visible: false)
    end
  end
end
