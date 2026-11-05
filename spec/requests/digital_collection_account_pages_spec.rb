# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'the digital collection sign in, password and sign up pages', type: :request, singletenant: true do
  let(:theme) { 'digital_collection' }
  let(:doc) { Nokogiri::HTML(response.body) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return(theme)
  end

  def expect_themed_page(title)
    expect(response).to have_http_status(:ok)
    expect(doc.at_css('body')['class']).to include('dc-account-page')
    expect(doc.at_css('.dc-masthead')).to be_present
    expect(doc.at_css('.dc-searchbar')).to be_present
    expect(doc.at_css('.dc-account h1.dc-account-title').text.strip).to eq(title)
  end

  it 'themes the sign in page' do
    get new_user_session_path

    expect_themed_page(I18n.t('digital_collection.account.sign_in.title'))
    expect(doc.at_css('.dc-account-form input.dc-account-submit')['value']).to eq(I18n.t('digital_collection.account.sign_in.submit'))
  end

  it 'marks the header Login link as the current page and leaves out the sign up link' do
    get new_user_session_path

    expect(doc.css('.dc-masthead a[aria-current="page"]').map { |a| a.text.strip }.uniq).to eq([I18n.t('hyrax.toolbar.profile.login')])
    expect(doc.css('.dc-account-links a').map { |a| a['href'] }).not_to include(a_string_including(new_user_registration_path))
  end

  context 'with single sign on providers' do
    before do
      IdentityProvider.create!(name: 'Campus Login', provider: 'saml', options: {})
      IdentityProvider.create!(name: 'Library Partners', provider: 'saml', options: {})
    end

    it 'themes the provider choice page' do
      get single_signon_index_path

      expect_themed_page(I18n.t('digital_collection.account.single_signon.title'))
      expect(doc.css('.dc-account-providers .dc-account-provider').map { |b| b.text.strip }).to eq(
        ['Campus Login', 'Library Partners'].map { |name| I18n.t('single_signon.index.sign_in_with_provider', provider: name) }
      )
      expect(doc.at_css('.dc-account-intro')).to be_nil
    end

    it 'offers each provider as a button on the sign in page' do
      get new_user_session_path

      expect(doc.css('.dc-account-links .dc-account-provider').size).to eq(2)
    end
  end

  it 'themes the forgot password page' do
    get new_user_password_path

    expect_themed_page(I18n.t('digital_collection.account.forgot_password.title'))
  end

  it 'themes the change password page and names the minimum length' do
    get edit_user_password_path(reset_password_token: 'token')

    expect_themed_page(I18n.t('digital_collection.account.change_password.title'))
    expect(doc.at_css('#user_password')['aria-describedby']).to eq('dc-password-minimum')
    expect(doc.at_css('#dc-password-minimum').text).to eq(
      I18n.t('digital_collection.account.change_password.minimum_length', count: Devise.password_length.min)
    )
  end

  it 'keeps the reset token when switching language on the change password page' do
    get edit_user_password_path(reset_password_token: 'token')

    hrefs = doc.css('.dc-masthead a[hreflang="de"]').map { |a| a['href'] }
    expect(hrefs).to be_present
    expect(hrefs).to all(include('reset_password_token=token').and(include('locale=de')))
  end

  it 'themes the sign up page with required markers on every field' do
    get new_user_registration_path

    expect_themed_page(I18n.t('digital_collection.account.sign_up.title'))
    expect(doc.css('.dc-account-form .dc-field').size).to eq(4)
    expect(doc.css('.dc-account-form .dc-field-required').size).to eq(4)
  end

  it 'shows a failed sign in on the themed page' do
    post user_session_path, params: { user: { email: 'nobody@example.com', password: 'wrong-password' } }
    follow_redirect! while response.redirect?

    expect_themed_page(I18n.t('digital_collection.account.sign_in.title'))
    expect(doc.at_css('#content-wrapper .alert').text).to include(I18n.t('devise.failure.invalid', authentication_keys: 'email'))
  end

  it 'shows the reset email notice on the themed sign in page' do
    user = FactoryBot.create(:user)

    post user_password_path, params: { user: { email: user.email } }
    follow_redirect!

    expect_themed_page(I18n.t('digital_collection.account.sign_in.title'))
    expect(doc.at_css('#content-wrapper .alert').text).to include(I18n.t('devise.passwords.send_instructions'))
  end

  it 'lists sign up errors above the fields' do
    post user_registration_path, params: { user: { display_name: 'Test Person', email: 'person@example.com', password: 'short', password_confirmation: 'other' } }

    expect(doc.at_css('.dc-account-form #error_explanation li')).to be_present
    expect(doc.at_css('.dc-account h1.dc-account-title').text.strip).to eq(I18n.t('digital_collection.account.sign_up.title'))
  end

  it 'translates the page copy' do
    get new_user_session_path(locale: 'de')

    expect(doc.at_css('h1.dc-account-title').text.strip).to eq(I18n.t('digital_collection.account.sign_in.title', locale: :de))
  end

  context 'with another home theme' do
    let(:theme) { 'heritage' }

    it 'keeps the stock sign in page' do
      get new_user_session_path

      expect(response).to have_http_status(:ok)
      expect(doc.at_css('.dc-account')).to be_nil
      expect(doc.at_css('body')['class']).not_to include('dc-account-page')
    end
  end
end
