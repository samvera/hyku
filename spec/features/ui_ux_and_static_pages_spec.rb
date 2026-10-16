# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'UI/UX and Static Pages', type: :feature, clean: true do
  it 'allows language selection and persists it' do
    visit '/'
    select('Español', from: 'Language')
    expect(page).to have_content('Inicio').or have_content('Página principal')
    visit '/'
    expect(page).to have_select('Language', selected: 'Español')
  end

  it 'navigates static pages: About, Help, Terms, Contact' do
    visit '/'
    click_link 'About'
    expect(page).to have_content('About')
    visit '/'
    click_link 'Help'
    expect(page).to have_content('Help')
    visit '/'
    click_link 'Terms of Use'
    expect(page).to have_content('Terms')
    visit '/'
    click_link 'Contact'
    expect(page).to have_content('Contact')
  end
end
