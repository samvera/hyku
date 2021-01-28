# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin can select home page theme', type: :feature, js: true, clean: true do
  context "as a repository admin" do
    let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com', display_name: 'Adam Admin') }

    it "has a tab for themes on the appearance tab" do
      login_as admin
      visit '/admin/appearance'
      expect(page).to have_content 'Appearance'
      click_link('Themes')
      expect(page).to have_content 'Home Page Theme'
    end
    
    it 'has a select box for the home, show, and search pages themes' do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Default home', from: 'Home Page Theme')
      select('Default search', from: 'Search Results Page Theme')
      select('Default show', from: 'Show Page Theme')
      find('body').click
      click_on('Save')
      expect(page).to have_content('The appearance was successfully updated')
    end

    it 'sets the them to default if no theme is selected' do
      visit '/'
      expect(page).to have_css('body.default_home.default_search.default_show')
    end

    # TODO: switch to other theme names when a theme has been implemented
    it 'sets the home page theme when the theme form is saved' do
      login_as admin
      visit 'admin/appearance'
      click_link('Themes')
      select('Default home', from: 'Home Page Theme')
      select('Default search', from: 'Search Results Page Theme')
      select('Default show', from: 'Show Page Theme')
      find('body').click
      click_on('Save')
      visit '/'
      expect(page).to have_css('body.default_home.default_search.default_show')
    end
  end
end