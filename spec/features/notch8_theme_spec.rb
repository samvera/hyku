# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin can select notch8 theme', type: :feature, js: true, clean: true do
  let(:account) { FactoryBot.create(:account) }
  let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com', display_name: 'Julie Admin') }

  context 'as a repository admin' do
    it 'sets the notch8 theme when the theme form is saved' do
      login_as admin
      visit 'admin/appearance'
      click_link('Themes')
      select('Notch 8', from: 'Home Page Theme')
      find('body').click
      click_on('Save')

      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)

      expect(site.home_theme).to eq('notch8')

      visit '/'
      expect(page).to have_css('body.notch8')
    end

    it 'displays theme notes and wireframe in admin panel' do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Notch 8', from: 'Home Page Theme')
      find('body').click

      expect(page).to have_content('This theme is for demoing Hyku features')
      expect(page).to have_content('This theme uses a custom banner image')
      expect(page).to have_content('This theme uses home page text')
      expect(page).to have_content('This theme uses marketing text')
      expect(page.find('#home-wireframe img')['src']).to match(%r{/assets/themes/notch8/})
    end
  end

  context 'when the notch8 theme is selected' do
    it 'renders the theme-specific layout' do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Notch 8', from: 'Home Page Theme')
      find('body').click
      click_on('Save')

      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)

      visit '/'

      # Theme CSS class applied
      expect(page).to have_css('body.notch8')

      # Theme sections present
      expect(page).to have_content('Featured Works')
      expect(page).to have_content('Collections')

      # Other themes' elements NOT present
      expect(page).not_to have_css('div.ir-stats')
      expect(page).not_to have_css('nav.cultural-repository-nav')
      expect(page).not_to have_css('div.institutional-repository-carousel')
    end

    it 'does not display featured researcher section' do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Notch 8', from: 'Home Page Theme')
      find('body').click
      click_on('Save')

      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)

      # Create featured researcher content
      ContentBlock.update_block(name: 'featured_researcher', value: '<h2>Test Researcher</h2>')

      visit '/'

      # Should NOT appear because featured_researcher: false
      expect(page).not_to have_content('Test Researcher')
      expect(page).not_to have_css('.featured-researcher')
    end

    it 'displays featured works section' do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Notch 8', from: 'Home Page Theme')
      find('body').click
      click_on('Save')

      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)

      visit '/'

      expect(page).to have_content('Featured Works')
      # Could also test for specific CSS classes if you add custom ones
    end

    it 'displays collections section' do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Notch 8', from: 'Home Page Theme')
      find('body').click
      click_on('Save')

      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)

      visit '/'

      expect(page).to have_content('Collections')
    end

    it 'displays navigation links in the masthead' do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Notch 8', from: 'Home Page Theme')
      find('body').click
      click_on('Save')

      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)

      page.driver.browser.manage.window.resize_to(1400, 1000)
      visit '/'
      # Test the navbar structure exists
      expect(page).to have_css('#masthead.notch8-masthead')
      expect(page).to have_css('#masthead .navbar-nav')

      # Test links exist (may be hidden by collapse)
      within('#masthead') do
        expect(page).to have_link('Home', visible: :all)
        expect(page).to have_link('About', visible: :all)
        expect(page).to have_link('Help', visible: :all)
        expect(page).to have_link('Contact', visible: :all)
      end
    end

    it 'displays search bar below the banner' do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Notch 8', from: 'Home Page Theme')
      find('body').click
      click_on('Save')

      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      visit '/'

      # Search section exists
      expect(page).to have_css('.notch8-search-section')

      expect(page).to have_css('#search-form-header')
      expect(page).to have_field('q')
      expect(page).to have_button('Go')
    end
  end
end
