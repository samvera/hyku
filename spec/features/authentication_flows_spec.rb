# frozen_string_literal: true

require 'rails_helper'
require 'cgi'

RSpec.describe 'Authentication and Account Flows', type: :feature, clean: true do
  let(:email) { "auth-#{SecureRandom.hex(6)}@example.com" }
  let(:password) { 'password123' }

  # Authenticates through the real sign-in form (not `login_as`), so Warden test
  # mode is not active and cannot re-inject the user on the next request. Devise
  # is configured with `config.sign_out_via = :get`, so following the Logout link
  # genuinely ends the session.
  it 'logs the user out when the Logout link is clicked' do
    create(:user, email:, password:, password_confirmation: password)

    visit '/users/sign_in'
    fill_in 'user_email', with: email
    fill_in 'user_password', with: password
    click_button 'Log in'
    expect(page).to have_content('Dashboard')
    expect(page).to have_link('Logout')

    click_link 'Logout'

    expect(page).to have_link('Login')
    expect(page).not_to have_link('Logout')
    visit '/users/sign_in'
    expect(page).to have_content('Log in')
    expect(page).not_to have_content('You are already signed in')
  end

  it 'allows user to sign up, log in, log out, and reset password' do
    visit '/users/sign_up'
    fill_in 'Your Name', with: 'Test User'
    fill_in 'Email', with: email
    fill_in 'user_password', with: 'password123'
    fill_in 'user_password_confirmation', with: 'password123'
    click_button 'Create account'
    expect(User.exists?(email:)).to be true
    click_link 'Logout'
    expect(page).to have_link('Login')
    visit '/users/sign_in'
    expect(page).to have_content('Log in')
    fill_in 'user_email', with: email
    fill_in 'user_password', with: password
    click_button 'Log in'
    expect(page).to have_content('Dashboard')
    click_link 'Logout'
    expect(page).to have_link('Login')
    visit new_user_session_path
    click_link 'Forgot your password?'
    expect(page).to have_content('Forgot your password?')
    ActionMailer::Base.deliveries.clear
    fill_in 'user_email', with: email
    click_button 'Send me reset password instructions'
    reset_email = ActionMailer::Base.deliveries.last
    expect(reset_email).to be_present
    expect(reset_email.body.encoded).to include('Change my password')
    reset_url = reset_email.body.encoded[/https?:[^\s"<>]+/]
    expect(reset_url).to be_present
    visit URI.parse(CGI.unescapeHTML(reset_url)).request_uri
    fill_in 'New password', with: 'newpassword123'
    fill_in 'Confirm new password', with: 'newpassword123'
    click_button 'Change my password'
    expect(page).to have_content('Your password has been changed successfully')

    # Devise signs the user in after a successful reset, so log out before
    # proving the new password works on a fresh sign-in.
    click_link 'Logout'
    expect(page).to have_link('Login')

    visit '/users/sign_in'
    expect(page).to have_content('Log in')
    fill_in 'user_email', with: email
    fill_in 'user_password', with: 'newpassword123'
    click_button 'Log in'
    expect(page).to have_content('Dashboard')
  end

  it 'validates login, signup, and password forms' do
    visit '/users/sign_up'
    expect(page).to have_css('.registration input[required]', count: 4)
    visit '/users/sign_in'
    click_button 'Log in'
    expect(page).to have_content(/Invalid email or password\./i)
    visit '/users/password/new'
    click_button 'Send me reset password instructions'
    expect(page).to have_content("can't be blank")
  end
end
