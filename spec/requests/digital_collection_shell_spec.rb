# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'the digital collection header and footer', type: :request, singletenant: true, clean_repo: true do
  include Devise::Test::IntegrationHelpers

  let(:home_theme) { 'digital_collection' }
  let(:show_theme) { 'digital_collection_show' }
  let(:doc) { Nokogiri::HTML(response.body) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return(home_theme)
    allow_any_instance_of(ApplicationController).to receive(:show_page_theme).and_return(show_theme)
    allow(Flipflop).to receive(:show_login_link?).and_return(true)
  end

  describe 'signed out' do
    before { get root_path }

    it 'keeps the site name out of the headings' do
      expect(doc.css('.dc-masthead h1')).to be_empty
      expect(doc.at_css('.dc-masthead #logo .institution_name')).to be_present
    end

    it 'shows the nav links, a log in link and a plain menu button' do
      expect(doc.css('.dc-masthead-nav > li > a.nav-link').map(&:text)).to eq(%w[Home About Help Contact])
      expect(doc.at_css('.dc-masthead-utilities a.dc-masthead-login')).to be_present
      expect(doc.at_css('.dc-menu-button')['aria-label']).to eq('Menu')
      expect(doc.at_css('.dc-menu-button')['aria-controls']).to eq('top-navbar-collapse')
      expect(doc.at_css('#dc-account-trigger')).to be_nil
    end

    it 'marks the current page in the nav' do
      expect(doc.at_css(".dc-masthead-nav a[aria-current='page']").text).to eq('Home')
    end
  end

  describe 'signed in' do
    let(:user) { FactoryBot.create(:user, display_name: 'M. Rivera') }
    let(:unread) { 0 }

    before do
      allow_any_instance_of(UserMailbox).to receive(:unread_count).and_return(unread)
      sign_in user
      get root_path
    end

    it 'shows the account menu instead of the log in link, with no bell when nothing is unread' do
      trigger = doc.at_css('#dc-account-trigger')

      expect(trigger['aria-label']).to eq(user.name)
      expect(trigger.at_css('.dc-masthead-bell')).to be_nil
      expect(doc.at_css('.dc-masthead-login')).to be_nil
      expect(doc.css('.dc-masthead-dropdown .dc-menu-item').map { |a| a.text.strip }).to include('Dashboard', 'Notifications', I18n.t('hyrax.toolbar.profile.logout'))
      expect(doc.at_css('.dc-menu-header').text).to include(I18n.t('digital_collection.chrome.signed_in_as'))
    end

    it 'repeats the account links in the collapsed menu' do
      section = doc.at_css('.dc-masthead-section')

      expect(section.at_css('.dc-masthead-section-label').text).to eq("Signed in as #{user.name}")
      expect(section.css('a.nav-link').map(&:text)).to include('Dashboard', 'Notifications', I18n.t('hyrax.toolbar.profile.logout'))
    end

    context 'with unread notifications' do
      let(:unread) { 3 }

      it 'leads the name with a bell and says the count in words' do
        trigger = doc.at_css('#dc-account-trigger')

        expect(trigger['aria-label']).to eq("#{user.name}, 3 unread notifications")
        expect(trigger.at_css(".dc-masthead-bell[aria-hidden='true'] .notify-number .count").text).to eq('3')
        expect(doc.css('.dc-masthead-dropdown .dc-menu-item').map { |a| a.text.strip }).to include('Notifications (3)')
      end

      it 'puts the count on the menu button too' do
        button = doc.at_css('.dc-menu-button')

        expect(button['aria-label']).to eq('Menu, 3 unread notifications')
        expect(button.at_css(".dc-unread-count[aria-hidden='true']").text).to eq('3')
      end
    end
  end

  describe 'the announcement' do
    before { ContentBlock.find_or_create_by(name: 'announcement_text').update!(value: '<p>Closed Monday</p>') }

    it 'sits above the header as an info band on the homepage' do
      get root_path

      expect(response.body.index('dc-announcement')).to be < response.body.index('class="top-header dc-masthead"')
      expect(doc.at_css('.dc-announcement .dc-announcement-label').text).to eq('Notice:')
      expect(doc.at_css(".dc-announcement .fa-info-circle[aria-hidden='true']")).to be_present
    end

    it 'stays off other pages' do
      get search_catalog_path

      expect(doc.at_css('.dc-announcement')).to be_nil
    end
  end

  describe 'one main heading per page' do
    def level_one_headings
      doc.css('h1, [role="heading"][aria-level="1"]')
    end

    def block(name, value)
      ContentBlock.find_or_create_by(name:).update!(value:)
    end

    it 'falls back to the default hero headline when no content blocks are set' do
      get root_path

      expect(level_one_headings.map { |h| h.text.strip }).to eq([I18n.t('digital_collection.homepage.hero.headline')])
    end

    it 'keeps one h1 when an uploaded logo replaces the site name' do
      allow_any_instance_of(Site).to receive(:logo_image?).and_return(true)
      allow_any_instance_of(Site).to receive(:logo_image).and_return(double(url: '/uploads/logo.png'))
      get root_path

      expect(doc.at_css('.dc-masthead #logo img')).to be_present
      expect(doc.css('.dc-masthead h1, .dc-masthead [role="heading"]')).to be_empty
      expect(level_one_headings.size).to eq(1)
    end

    it 'marks plain marketing text as the level one heading' do
      block('marketing_text', '<p>Letters, maps and photographs</p>')
      get root_path

      expect(level_one_headings.size).to eq(1)
      expect(level_one_headings.first.text).to include('Letters, maps and photographs')
    end

    it 'makes the first heading in the marketing text the h1 and leaves the subline as text' do
      block('marketing_text', '<h2>Maps of the Hudson</h2><p>Since 1850</p><h1>Another</h1>')
      get root_path

      expect(level_one_headings.map { |h| h.text.strip }).to eq(['Maps of the Hudson'])
      expect(doc.at_css('.dc-hero-headline[role]')).to be_nil
      expect(doc.at_css('.dc-hero-headline p').text).to eq('Since 1850')
      expect(doc.at_css('.dc-hero-headline h2').text).to eq('Another')
    end

    it 'turns an h1 typed into the other homepage blocks into an h2' do
      block('home_text', '<h1>Welcome</h1>')
      block('homepage_about_section_content', '<h1>About us</h1>')
      block('announcement_text', '<h1>Closed Monday</h1>')
      get root_path

      expect(level_one_headings.size).to eq(1)
      expect(doc.css('h2').map(&:text)).to include('Welcome', 'About us', 'Closed Monday')
    end

    it 'gives content pages a single h1 with the page name, even when the content has its own h1' do
      ContentBlock.find_or_create_by(name: 'about_page').update!(value: '<h1>Our story</h1><p>Founded in 1890.</p>')
      get hyrax.about_path

      expect(doc.css('h1').map(&:text)).to eq([I18n.t('hyrax.pages.tabs.about_page')])
      expect(doc.at_css('#content_block_page h2').text).to eq('Our story')
    end
  end

  describe 'the footer' do
    it 'renders on the homepage with its log in link' do
      get root_path

      expect(doc.at_css('footer.navbar .navbar-link')).to be_present
    end
  end

  describe 'mixed theme pairings' do
    context 'with the digital collection home theme and the heritage show theme' do
      let(:show_theme) { 'heritage_show' }

      it 'uses the digital collection header on search pages' do
        get search_catalog_path

        expect(response).to have_http_status(:ok)
        expect(doc.at_css('.dc-masthead')).to be_present
      end
    end

    context 'with the heritage home theme and the digital collection show theme' do
      let(:home_theme) { 'heritage' }

      it 'still renders the homepage' do
        get root_path

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
