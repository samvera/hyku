# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Advanced Search', type: :feature, js: true, clean: true do
  include Warden::Test::Helpers

  context 'with unauthenticated user' do
    it 'can perform search' do
      visit '/'
      fill_in('q', with: 'ambitious aardvark')
      click_button('Go')
      expect(page).to have_content('ambitious aardvark')
      expect(page).to have_content('No results found for your search')
    end

    it 'can perform advanced search' do
      visit '/advanced'
      fill_in('Title', with: 'ambitious aardvark')
      search_btn = find('#advanced-search-submit')
      # we send keys because the mocked web page didn't pick up the css change
      # to prevent the footer from covering up the submit button
      search_btn.send_keys :enter
      expect(page).to have_content('ambitious aardvark')
      expect(page).to have_content('No results found for your search')
    end
  end
end
