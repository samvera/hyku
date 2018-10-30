RSpec.describe 'Proprietor administration', multitenant: true do
  context 'as an superadmin' do
    let(:user) { FactoryBot.create(:superadmin) }

    before do
      login_as(user, scope: :user)
      Capybara.default_host = "http://#{Account.admin_host}"
    end

    it 'has a navbar link to an account admin section' do
      visit '/'
      click_on 'Accounts'
      expect(page).to have_link 'Create new account'
    end

    it 'has a navbar link to logout' do
      visit '/'
      expect(page).to have_link 'Logout'
    end
  end
end
