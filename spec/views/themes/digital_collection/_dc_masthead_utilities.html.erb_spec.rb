# frozen_string_literal: true

RSpec.describe 'themes/digital_collection/_dc_masthead_utilities.html.erb', type: :view do
  let(:languages) { { 'en' => 'English' } }
  let(:show_login) { true }
  let(:utilities) { Capybara.string(rendered) }

  before do
    without_partial_double_verification do
      allow(view).to receive(:available_translations).and_return(languages)
      allow(view).to receive(:user_signed_in?).and_return(false)
      allow(view).to receive(:admin_host?).and_return(false)
    end
    allow(Flipflop).to receive(:show_login_link?).and_return(show_login)
    render partial: 'themes/digital_collection/dc_masthead_utilities', locals: { unread: 0 }
  end

  it 'leaves out the language menu when there is only one language' do
    expect(utilities).to have_no_css('#dc-language-trigger')
    expect(utilities).to have_no_css('.dc-language-row')
  end

  it 'shows a log in link when the login link is switched on' do
    expect(utilities).to have_css('.dc-masthead-utilities a.dc-masthead-login', text: I18n.t('hyrax.toolbar.profile.login'))
    expect(utilities).to have_no_css('.dc-masthead-login .fa')
  end

  context 'when the login link is switched off' do
    let(:show_login) { false }

    it 'shows no log in link' do
      expect(utilities).to have_no_css('.dc-masthead-login')
      expect(utilities).to have_no_css('.dc-masthead-section')
    end
  end

  context 'with several languages' do
    let(:languages) { { 'en' => 'English', 'es' => 'Español', 'fr' => 'Français' } }

    it 'shows each language in its own language and checks the current one' do
      expect(utilities).to have_css('#dc-language-trigger', text: 'English')
      expect(utilities).to have_css(".dc-masthead-dropdown a.dc-menu-item[lang='es'][hreflang='es']", text: 'Español')
      expect(utilities).to have_css(".dc-masthead-dropdown a.dc-menu-item[aria-current='true'][lang='en'] .dc-menu-check")
      expect(utilities).to have_css(".dc-language-row a[lang='fr']", text: 'Français')
    end
  end
end
