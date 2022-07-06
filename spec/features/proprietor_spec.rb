# frozen_string_literal: true

RSpec.describe 'Proprietor administration', multitenant: true do
  context 'as an superadmin' do
    let(:user) { FactoryBot.create(:superadmin) }

    before do
      login_as(user, scope: :user)
    end

    around do |example|
      default_host = Capybara.default_host
      Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
      example.run
      Capybara.default_host = default_host
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

    it "has validation for password" do
      visit '/proprietor/users/new'
      fill_in "user_email", with: user.email
      fill_in "user_password", with: ""
      click_on "Save"
      byebug
      message = page.find("#user_password").native.attribute("validationMessage")
      expect(message).to eq "Please fill out this field."
    end

  end
end
