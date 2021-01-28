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
    
    it "has a select box for the home page theme" do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Default theming', from: 'Home Page Theme')
      select('Default theming', from: 'Search Results Page Theme')
      select('Default theming', from: 'Show Page Theme')

      find('body').click
      click_on('Save')
      expect(page).to have_content("The appearance was successfully updated")
    end
  end
end