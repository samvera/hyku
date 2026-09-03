# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Practice Research themes', type: :feature, js: true, clean: true do
  let(:account) { FactoryBot.create(:account_with_public_schema) }
  let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com', display_name: 'Adam Admin') }

  it 'offers both themes on the appearance page and applies them' do
    login_as admin
    visit '/admin/appearance'
    click_link('Themes')
    select('Practice Research', from: 'Home Page Theme')
    select('Practice Research Show Page', from: 'Show Page Theme')
    find('body').click
    click_on('Save')

    site = Site.last
    account.sites << site
    allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
    expect(site.home_theme).to eq('practice_research')
    expect(site.show_theme).to eq('practice_research_show')

    visit '/'
    expect(page).to have_css('body.practice_research.practice_research_show')
    expect(page).to have_css('.pr-hero')
    expect(page).to have_css('.pr-about')
  end
end
