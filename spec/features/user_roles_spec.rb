# frozen_string_literal: true

# NOTE: If want to run spec in browser, you have to set "js: true"
RSpec.describe 'User Roles' do
  let(:account) { create(:account) }

  context 'as a user manager' do
    let!(:group_1) { FactoryBot.create(:group) }
    let(:user_manager) { FactoryBot.create(:user_manager) }

    before do
      FactoryBot.create(:user, email: 'user@example.com', display_name: 'Regular User')
      login_as(user_manager, scope: :user)
    end

    it 'can view Manage Users and Manage Groups in the dashboard sidebar' do
      visit "/dashboard"
      expect(page).to have_content 'Manage Users'
      expect(page).to have_content 'Manage Groups'
    end

    it 'can visit Manage Users and invite users' do
      visit "/admin/users"
      fill_in "Email address", with: 'user@test.com'
      select "User Reader", from: 'user_role'
      click_on "Invite user"
      expect(page).to have_content 'An invitation email has been sent to user@test.com.'
    end

    it 'can visit Manage Users but cannot delete users' do
      visit "/admin/users"
      expect(page).not_to have_link 'Delete'
    end

    it 'can visit the users index page' do
      visit "/users"
      expect(page).to have_content 'Hyku Users'
    end

    it 'can visit a users showpage and see the Edit Profile button' do
      visit "/users/user@example-dot-com"
      expect(page).to have_link 'Edit Profile'
    end

    it 'can visit a users profile showpage' do
      visit "/dashboard/profiles/user@example-dot-com"
      expect(page).to have_content 'Profile'
      expect(page).to have_content 'user@example.com'
    end

    it 'can edit a users profile' do
      visit "/dashboard/profiles/user@example-dot-com/edit"
      expect(page).to have_content 'Edit Profile'
      expect(page).to have_button 'Save Profile'
    end

    it 'can view groups and roles' do
      visit "/admin/groups"
      expect(page).to have_content 'Manage Groups'
      expect(page).to have_link 'Create New Group'
      expect(page).to have_link 'Edit group & users'
    end

    it 'can edit groups name' do
      visit "/admin/groups/#{group_1.id}/edit"
      expect(page).to have_content 'Edit Group:'
    end

    it 'can edit groups users' do
      visit "/admin/groups/#{group_1.id}/users"
      expect(page).to have_content 'Current Group Members'
      expect(page).to have_link 'Remove'
    end

    it 'can edit groups roles' do
      visit "/admin/groups/#{group_1.id}/roles"
      expect(page).to have_content 'Current Group Roles'
      expect(page).to have_content 'Add Roles to Group'
    end

    it 'can remove a group' do
      visit "/admin/groups/#{group_1.id}/remove"
      expect(page).to have_content 'Remove Group'
      expect(page).to have_content 'This action is irreversible. It will remove all privileges ' \
                                   'group members have been assigned through this group.'
    end
  end

  context 'as a user reader' do
    let(:user_reader) { FactoryBot.create(:user_reader) }

    before do
      FactoryBot.create(:user, email: 'user@example.com', display_name: 'User Reader')
      login_as(user_reader, scope: :user)
    end

    it 'can view the users index page' do
      visit "/users"
      expect(page).to have_content 'Hyku Users'
    end

    it 'can view a users showpage' do
      visit "/users/user@example-dot-com"
      expect(page).to have_content 'Email'
      expect(page).to have_content 'user@example.com'
    end

    it 'can view a users profile' do
      visit "/dashboard/profiles/user@example-dot-com"
      expect(page).to have_content 'Profile'
      expect(page).to have_content 'user@example.com'
    end

    it 'cannot edit a users profile' do
      visit "/dashboard/profiles/user@example-dot-com/edit"
      expect(page).to have_content 'Unauthorized'
      expect(page).to have_content 'The page you have tried to access is private'
    end

    it 'can view Manage Users and Manage Groups in the dashboard sidebar' do
      visit "/dashboard"
      expect(page).to have_content 'Manage Users'
      expect(page).to have_content 'Manage Groups'
    end

    it 'can visit Manage Users and cant invite users' do
      visit "/admin/users"
      expect(page).not_to have_content 'Invite user'
    end

    it 'can visit Manage Users and cant delete users' do
      visit "/admin/users"
      expect(page).not_to have_link 'Delete'
    end
  end

  context 'as a registered user' do
    let(:user) { FactoryBot.create(:user) }

    before do
      FactoryBot.create(:user, email: 'user@example.com', display_name: 'Regular User')
      login_as(user, scope: :user)
    end

    it 'cannot view Manage Users and Manage Groups in the dashboard sidebar' do
      visit "/dashboard"
      expect(page).not_to have_content 'Manage Users'
      expect(page).not_to have_content 'Manage Groups'
    end

    it 'cannot view users index page' do
      visit "/users"
      expect(page).to have_content 'You are not authorized to access this page.'
    end

    it 'cannot view a users showpage' do
      visit "/users/user@example-dot-com"
      expect(page).to have_content 'You are not authorized to access this page.'
    end

    it 'cannot edit a users profile' do
      visit "/dashboard/profiles/user@example-dot-com/edit"
      expect(page).to have_content 'The page you have tried to access is private'
    end

    it 'cannot view the manage groups page' do
      visit "/admin/groups"
      expect(page).to have_content 'You are not authorized to access this page.'
    end

    it 'cannot view the manage users page' do
      visit "/admin/users"
      expect(page).to have_content 'You are not authorized to access this page.'
    end

    it 'can view own profile' do
      visit "/dashboard"
      click_on "Your activity"
      click_on "Profile"
      expect(page).to have_content "Profile"
      expect(page).to have_content user.email.to_s
      expect(page).to have_content "Edit Profile"
    end

    it 'can edit own profile' do
      visit "/dashboard"
      click_on "Your activity"
      click_on "Profile"
      click_on "Edit Profile"
      expect(page).to have_content "Change picture"
      expect(page).to have_content "ORCID Profile"
      expect(page).to have_content "Twitter Handle"
      expect(page).to have_content "Facebook Handle"
      expect(page).to have_content "Google+ Handle"
      fill_in "user_orcid", with: "0000-0000-0000-0000"
      click_on "Save Profile"
      expect(page).to have_content "Your profile has been updated"
      expect(page).to have_content "https://orcid.org/0000-0000-0000-0000"
    end
  end

  context 'as an unregistered user' do
    it 'can sign up' do
      visit "/"
      click_on "Login"
      click_on "Sign up"
      fill_in "Email address", with: 'user@example.com'
      fill_in "user_password", with: 'testing123'
      fill_in "user_password_confirmation", with: 'testing123'
      click_on "Create account"
      expect(page).to have_content "Welcome! You have signed up successfully."
    end
  end
end
