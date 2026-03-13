# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin can select institutional repository theme', type: :feature, js: true, clean: true do # rubocop:disable Layout/LineLength
  let(:account) { FactoryBot.create(:account) }
  let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com', display_name: 'Adam Admin') }
  let(:user) { create :user }
  let!(:work) do
    create(:generic_work,
           title: ['Llamas and Alpacas'],
           keyword: ['llama', 'alpaca'],
           resource_type: ['Software or Program Code'],
           user:)
  end

  context 'as a repository admin' do
    it 'sets the institutional repository theme when the theme form is saved' do
      login_as admin
      visit 'admin/appearance'
      click_link('Themes')
      select('Institutional Repository', from: 'Home Page Theme')
      find('body').click
      click_on('Save')
      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      expect(site.home_theme).to eq('institutional_repository')
      visit '/'
      expect(page).to have_css('body.institutional_repository')
    end
  end

  context 'when the institutional repository theme is selected' do
    it 'renders the partials in the theme folder' do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Institutional Repository', from: 'Home Page Theme')
      find('body').click
      click_on('Save')
      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      visit '/'
      expect(page).to have_css('body.institutional_repository')
      expect(page).to have_css('nav#masthead.institutional-repository-nav')
      expect(page).to have_css('div.ir-stats')
      expect(page).to have_css('div.institutional-repository-featured-researcher')
      expect(page).to have_css('div.institutional-repository-recent-uploads')
      expect(page).to have_css('div.col-12.col-md-8.institutional-repository.collections-container')
      expect(page).not_to have_css('ul#homeTabs')
      expect(page).not_to have_css('ul.nav.nav-pills')
      expect(page).not_to have_css('nav.navbar.cultural-repository-nav')
      expect(page).not_to have_css('background-container-gradient')
    end

    it 'renders the stats carousel if there are more than 6 resource_types' do
      work.resource_type = [
        'Article', 'Audio', 'Book', 'Capstone Project', 'Conference Proceeding', 'Dataset', 'Software or Program Code'
      ]
      work.save
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Institutional Repository', from: 'Home Page Theme')
      find('body').click
      click_on('Save')
      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      visit '/'
      expect(page).to have_css('div.institutional-repository-carousel')
    end
  end
end
