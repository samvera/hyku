# frozen_string_literal: true

require 'rails_helper'

# Manual Test Plan: "Homepage" (Language dropdown and the static page links).
RSpec.describe 'UI/UX and Static Pages', type: :feature, clean: true do
  # The language picker is a dropdown of links (shared/_locale_picker), not a <select>.
  # Hyku carries the chosen locale as a URL parameter: Hyrax sets I18n.locale from
  # params[:locale] and default_url_options adds `locale` to every generated link, so the
  # choice persists while navigating the site's links (it is not stored in a session).
  it 'switches the interface language and keeps it across the tenant pages' do
    visit '/'
    within('#language-dropdown-menu') { click_link 'Español' }

    expect(page).to have_link('Acerca de')
    expect(page).to have_link('Ayuda')
    expect(page).not_to have_link('Help')

    # Follow the nav through every static page and back home; each stays in Spanish.
    { 'Acerca de' => '/about', 'Ayuda' => '/help', 'Contacto' => '/contact', 'Hogar' => '/' }.each do |link, path|
      click_link link

      expect(page).to have_current_path(path, ignore_query: true)
      expect(page).to have_current_path(/locale=es/)
      expect(page).to have_link('Ayuda')
      expect(page).to have_link('Contacto')
      expect(page).not_to have_link('Help', exact: true)
      expect(page).not_to have_link('Contact', exact: true)
    end
  end

  it 'navigates static pages: Home, About, Help, Terms, Contact' do
    # The About/Help/Terms pages render their content block, so give each a distinctive body.
    ContentBlock.about_page = '<p>About marker: who runs this repository.</p>'
    ContentBlock.help_page = '<p>Help marker: how to deposit.</p>'
    ContentBlock.terms_page = '<p>Terms marker: rules of use.</p>'
    {
      'About' => ['/about', '#content_block_page', 'About marker'],
      'Help' => ['/help', '#content_block_page', 'Help marker'],
      'Terms of Use' => ['/terms', '#content_block_page', 'Terms marker'],
      'Contact' => ['/contact', 'h1', 'Contact Form']
    }.each do |link, (path, selector, text)|
      visit '/'
      click_link link
      # Assert the destination and its own content rather than the link text, which is always in the nav.
      expect(page).to have_current_path(path, ignore_query: true)
      expect(page).to have_css(selector, text:)
    end

    click_link 'Home'
    expect(page).to have_current_path('/', ignore_query: true)
    expect(page).to have_css('#homeTabs')
  end
end
