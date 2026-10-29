# frozen_string_literal: true

require 'rails_helper'

# Devise pages served on the global (admin) host: app/views/devise/{sessions,registrations,passwords}
# plus the gem's passwords/edit view, and the links in app/views/devise/shared/_links.html.erb.
RSpec.describe 'Global authentication pages', type: :feature, multitenant: true, clean: true do
  around do |example|
    original_host = Capybara.default_host
    Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
    example.run
    Capybara.default_host = original_host
  end

  let(:password) { 'Correct-Horse-42' }
  let!(:user) do
    create(:user, email: 'global.login@example.com', display_name: 'Global Login', password:, password_confirmation: password)
  end

  # Manual Test Plan: "Global Administrator / User Login Page"
  describe 'Log in page' do
    it 'shows an email field (type=email), a password field, a Remember me box and a Log in button' do
      visit new_user_session_path

      expect(page).to have_css('h2', text: 'Log in')
      expect(page).to have_field('Email', type: 'email')
      expect(page).to have_field('Password', type: 'password')
      expect(page).to have_unchecked_field('Remember me')
      expect(page).to have_button('Log in')
    end

    it 'rejects an email that has no account and stays on the form' do
      visit new_user_session_path
      fill_in 'Email', with: 'nobody.here@example.com'
      fill_in 'Password', with: password
      click_button 'Log in'

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
      expect(page).to have_css('.alert', text: 'Invalid email or password.')
      expect(page).not_to have_link('Logout')
    end

    # The browser enforces the email format (type=email); a malformed address that reaches the
    # server is rejected by Devise the same way as an unknown one.
    it 'rejects a malformed email' do
      visit new_user_session_path
      fill_in 'Email', with: 'not-an-email'
      fill_in 'Password', with: password
      click_button 'Log in'

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
      expect(page).to have_css('.alert', text: 'Invalid email or password.')
    end

    it 'rejects the wrong password for an existing account' do
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'Wrong-Password-99'
      click_button 'Log in'

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
      expect(page).to have_css('.alert', text: 'Invalid email or password.')
      expect(page).not_to have_link('Logout')
    end

    it 'logs in with valid credentials and lands on the Global Index' do
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      click_button 'Log in'

      expect(page).to have_current_path('/', ignore_query: true)
      expect(page).to have_css('.alert', text: 'Signed in successfully.')
      within('#user_utility_links') { expect(page).to have_link('Logout') }
      expect(page.driver.browser.rack_mock_session.cookie_jar.to_hash.keys).not_to include('remember_user_token')
    end

    # Devise "Remember me" persists the sign-in in a remember cookie; it does not prefill the email
    # on the form (that part of the plan is browser autofill, not application behavior).
    it 'sets the remember cookie only when Remember me is checked' do
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: password
      check 'Remember me'
      click_button 'Log in'

      expect(page).to have_current_path('/', ignore_query: true)
      expect(page.driver.browser.rack_mock_session.cookie_jar.to_hash.keys).to include('remember_user_token')
      expect(user.reload.remember_created_at).to be_present
    end

    it 'links Forgot your password? to the Forgot your password form' do
      visit new_user_session_path
      click_link 'Forgot your password?'

      expect(page).to have_current_path(new_user_password_path, ignore_query: true)
      expect(page).to have_css('h2', text: 'Forgot your password?')
    end

    # _links renders Sign up only when !Account.global_tenant? && current_account.allow_signup.
    # Account.global_tenant? is hard-wired to false in the test environment, and the admin host's
    # current_account is an unsaved Account.new whose allow_signup defaults to true, so the link shows here.
    it 'links Sign up to the Create a new account form' do
      visit new_user_session_path
      click_link 'Sign up'

      expect(page).to have_current_path(new_user_registration_path, ignore_query: true)
      expect(page).to have_css('h2', text: 'Create a new account')
    end

    it 'hides the Sign up link when the request is on the global tenant' do
      allow(Account).to receive(:global_tenant?).and_return(true)
      visit new_user_session_path

      expect(page).to have_link('Forgot your password?')
      expect(page).not_to have_link('Sign up')
    end
  end

  # Manual Test Plan: "Global Sign Up Page"
  describe 'Sign up page' do
    # Your Name is enforced only by the browser (required attribute): User has no display_name validation.
    it 'shows required Your Name, Email address, Password and Password confirmation inputs' do
      visit new_user_registration_path

      expect(page).to have_css('input#user_display_name[required]')
      expect(page).to have_css('input#user_email[type="email"][required]')
      expect(page).to have_css('input#user_password[type="password"][required]')
      expect(page).to have_css('input#user_password_confirmation[type="password"][required]')
      expect(page).to have_button('Create account')
    end

    it 'does not register anyone when the required inputs are missing' do
      visit new_user_registration_path

      expect { click_button 'Create account' }.not_to change(User, :count)
      expect(page).to have_content('Please review the problems below:')
      within('.user_email') { expect(page).to have_content("can't be blank") }
      within('.user_password') { expect(page).to have_content("can't be blank") }
    end

    it 'does not register anyone with an invalid email, short password or mismatched confirmation' do
      visit new_user_registration_path
      fill_in 'Your Name', with: 'Rejected Registrant'
      fill_in 'Email address', with: 'not-an-email'
      fill_in 'user_password', with: 'short'
      fill_in 'Password confirmation', with: 'different'

      expect { click_button 'Create account' }.not_to change(User, :count)
      within('.user_email') { expect(page).to have_content('is invalid') }
      within('.user_password') { expect(page).to have_content("is too short (minimum is #{Devise.password_length.min} characters)") }
      within('.user_password_confirmation') { expect(page).to have_content("doesn't match Password") }
    end

    it 'rejects an email that is already registered' do
      visit new_user_registration_path
      fill_in 'Your Name', with: 'Duplicate Registrant'
      fill_in 'Email address', with: user.email
      fill_in 'user_password', with: password
      fill_in 'Password confirmation', with: password

      expect { click_button 'Create account' }.not_to change(User, :count)
      within('.user_email') { expect(page).to have_content('has already been taken') }
    end

    it 'registers a new user, signs them in and lands on the Global Index' do
      visit new_user_registration_path
      fill_in 'Your Name', with: 'Brand New Registrant'
      fill_in 'Email address', with: 'brand.new.registrant@example.com'
      fill_in 'user_password', with: password
      fill_in 'Password confirmation', with: password
      click_button 'Create account'

      expect(page).to have_current_path('/', ignore_query: true)
      expect(page).to have_css('.alert', text: 'Welcome! You have signed up successfully.')
      within('#user_utility_links') { expect(page).to have_link('Logout') }
      created = User.find_by!(email: 'brand.new.registrant@example.com')
      expect(created.display_name).to eq('Brand New Registrant')
      expect(created.valid_password?(password)).to be(true)
    end

    it 'links Log in to the Log in form' do
      visit new_user_registration_path
      click_link 'Log in'

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
      expect(page).to have_button('Log in')
    end

    it 'links Forgot your password? to the Forgot your password form' do
      visit new_user_registration_path
      click_link 'Forgot your password?'

      expect(page).to have_current_path(new_user_password_path, ignore_query: true)
    end

    it 'links Administrator login in the footer to the Log in form' do
      skip('No footer here: app/views/layouts/hyrax.html.erb renders shared/_footer only for splash and homepage')
    end
  end

  # Manual Test Plan: "Global Forgot your Password? Page"
  describe 'Forgot your password page' do
    before { ActionMailer::Base.deliveries.clear }

    it 'shows an Email input' do
      visit new_user_password_path

      expect(page).to have_field('Email', type: 'email')
      expect(page).to have_button('Send me reset password instructions')
    end

    it 'rejects a blank email without sending anything' do
      visit new_user_password_path
      click_button 'Send me reset password instructions'

      expect(page).to have_content("Email can't be blank")
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'rejects an email with no account (including a malformed one) without sending anything' do
      ['nobody.here@example.com', 'not-an-email'].each do |email|
        visit new_user_password_path
        fill_in 'Email', with: email
        click_button 'Send me reset password instructions'

        expect(page).to have_content('Email not found')
      end
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'emails reset instructions whose Change my password link opens the Change your password form' do
      visit new_user_password_path
      fill_in 'Email', with: user.email
      click_button 'Send me reset password instructions'

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
      expect(page).to have_css('.alert', text: 'You will receive an email with instructions on how to reset your password in a few minutes.')
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([user.email])

      link = Capybara.string(mail.body.encoded).find_link('Change my password')
      visit URI.parse(link[:href]).request_uri

      expect(page).to have_css('h2', text: 'Change your password')
      expect(page).to have_field('New password')
    end

    it 'links Log in to the Log in form' do
      visit new_user_password_path
      click_link 'Log in'

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
    end

    it 'links Sign up to the Create a new account form' do
      visit new_user_password_path
      click_link 'Sign up'

      expect(page).to have_current_path(new_user_registration_path, ignore_query: true)
      expect(page).to have_css('h2', text: 'Create a new account')
    end

    it 'links Administrator login in the footer to the Log in form' do
      skip('No footer here: app/views/layouts/hyrax.html.erb renders shared/_footer only for splash and homepage')
    end
  end

  # Manual Test Plan: "Change your password page"
  describe 'Change your password page' do
    let(:new_password) { 'Brand-New-Secret-7' }
    let(:token) { user.send_reset_password_instructions }

    before { visit edit_user_password_path(reset_password_token: token) }

    it 'shows New password and Confirm new password fields' do
      expect(page).to have_css('h2', text: 'Change your password')
      expect(page).to have_field('New password', type: 'password')
      expect(page).to have_field('Confirm new password', type: 'password')
      expect(page).to have_button('Change my password')
    end

    it 'rejects a password that is too short' do
      fill_in 'New password', with: 'short'
      fill_in 'Confirm new password', with: 'short'
      click_button 'Change my password'

      expect(page).to have_content("Password is too short (minimum is #{Devise.password_length.min} characters)")
      expect(user.reload.valid_password?(password)).to be(true)
    end

    it 'rejects a confirmation that does not match' do
      fill_in 'New password', with: new_password
      fill_in 'Confirm new password', with: 'Something-Else-8'
      click_button 'Change my password'

      expect(page).to have_content("Password confirmation doesn't match Password")
      expect(user.reload.valid_password?(new_password)).to be(false)
    end

    it 'changes the password, signs me in on the Global Index, and the new password works for log in' do
      fill_in 'New password', with: new_password
      fill_in 'Confirm new password', with: new_password
      click_button 'Change my password'

      expect(page).to have_current_path('/', ignore_query: true)
      expect(page).to have_css('.alert', text: 'Your password has been changed successfully. You are now signed in.')
      expect(user.reload.valid_password?(new_password)).to be(true)

      within('#user_utility_links') { click_link 'Logout' }
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: new_password
      click_button 'Log in'
      expect(page).to have_css('.alert', text: 'Signed in successfully.')
    end

    it 'links Log in to the Log in form' do
      click_link 'Log in'

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
    end

    it 'links Sign up to the Create a new account form' do
      click_link 'Sign up'

      expect(page).to have_current_path(new_user_registration_path, ignore_query: true)
    end

    it 'links Administrator login in the footer to the Log in form' do
      skip('No footer here: app/views/layouts/hyrax.html.erb renders shared/_footer only for splash and homepage')
    end
  end
end
