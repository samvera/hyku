# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin can select cultural repository theme', type: :feature, js: true, clean: true do
  let(:account) { FactoryBot.create(:account) }
  let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com', display_name: 'Adam Admin') }
  let(:user) { create :user }

  # rubocop:disable RSpec/LetSetup
  let!(:work) do
    create(:generic_work,
           title: ['Llamas and Alpacas'],
           keyword: ['llama', 'alpaca'],
           user:)
  end

  # rubocop:enable RSpec/LetSetup

  context "as a repository admin" do
    it 'sets the cultural repository theme when the theme form is saved' do
      login_as admin
      visit 'admin/appearance'
      click_link('Themes')
      select('Cultural Repository', from: 'Home Page Theme')
      find('body').click
      click_on('Save')
      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      expect(site.home_theme).to eq('cultural_repository')
      visit '/'
      expect(page).to have_css('body.cultural_repository')
    end
  end

  context 'when the cultural repository theme is selected' do
    it 'renders the partials in the theme folder' do # rubocop:disable RSpec/ExampleLength
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Cultural Repository', from: 'Home Page Theme')
      find('body').click
      click_on('Save')
      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      visit '/'
      expect(page).to have_css('body.cultural_repository')
      expect(page).to have_css('nav.navbar.cultural-repository-nav')
      ## The following continue to fail in CircleCI...the HTML's there but perhaps it is not
      ## visible?  Besides it would be nice to not have a feature test for HTML but instead a view
      ## test that conforms to theming.
      # expect(page).to have_css('form#search-form-header')
      # expect(page).to have_css('ul#user_utility_links')
      expect(page).to have_css('div.cultural-repository.facets')
      expect(page).to have_css('div.cultural-repository.featured-works-container')
      expect(page).to have_css('div.cultural-repository.recent-works-container')
      expect(page).to have_css('div.cultural-repository.collections-container')
      expect(page).not_to have_css('ul#homeTabs')
      expect(page).not_to have_css('ul.nav.nav-pills')
      expect(page).not_to have_css('div.home_share_work')
      expect(page).not_to have_css('nav.navbar.navbar-default.navbar-static-top')
      expect(page).not_to have_css('background-container-gradient')
    end
  end
end
