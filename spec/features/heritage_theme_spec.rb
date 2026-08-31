# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Heritage themes', type: :feature, js: true, clean: true do
  let(:account) { FactoryBot.create(:account_with_public_schema) }
  let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com', display_name: 'Adam Admin') }

  it 'offers both themes on the appearance page and applies them' do
    login_as admin
    visit '/admin/appearance'
    click_link('Themes')
    select('Heritage', from: 'Home Page Theme')
    select('Heritage Show Page', from: 'Show Page Theme')
    find('body').click
    click_on('Save')

    site = Site.last
    account.sites << site
    allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
    expect(site.home_theme).to eq('heritage')
    expect(site.show_theme).to eq('heritage_show')

    visit '/'
    # Hyku's layout writes the home, search, and show theme classes onto the body of
    # every page, so the show-page class rides the home page too — not a typo
    expect(page).to have_css('body.heritage.heritage_show')
    expect(page).to have_css('.hrt-hero')
    expect(page).to have_css('.hrt-hero-search')
  end
end
