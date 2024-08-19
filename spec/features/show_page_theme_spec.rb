# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin can select show page theme', type: :feature, js: true, clean: true do
  let(:account) { FactoryBot.create(:account) }
  let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com', display_name: 'Adam Admin') }
  let(:user) { create :user }
  let!(:work) do
    create(:generic_work,
           title: ['Giant Pandas and Red Pandas'],
           keyword: ['panda'],
           user:)
  end

  let(:admin_set_id) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id }
  let(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id) }
  let(:workflow) do
    Sipity::Workflow.create!(
      active: true,
      name: 'test-workflow',
      permission_template:
    )
  end

  before do
    Hyrax::Group.create(name: "admin")
    Hyrax::Group.create(name: "registered")
  end

  context "as a repository admin" do
    it 'has a select box for the show page themes' do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Default Show Page', from: 'Show Page Theme')
      find('body').click
      click_on('Save')
      expect(page).to have_content('The appearance was successfully updated')
    end

    it 'sets the theme to default if no theme is selected' do
      visit '/'
      expect(page).to have_css('body.default_home.list_view.default_show')
    end

    it 'sets the themes when the theme form is saved' do
      login_as admin
      visit 'admin/appearance'
      click_link('Themes')
      select('Default Show Page', from: 'Show Page Theme')
      find('body').click
      click_on('Save')
      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      expect(site.show_theme).to eq('default_show')
      visit '/'
      expect(page).to have_css('body.default_show')
    end
  end

  context 'when a show page theme is selected' do
    it 'renders theme notes and wireframe' do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Cultural Show Page', from: 'Show Page Theme')
      find('body').click
      expect(page).to have_content('This image based show page is recommended for cultural repositories.')
      expect(page.find('#show-wireframe img')['src']).to match(%r{/assets\/themes\/cultural_show/})
    end

    it 'renders the partials in the theme folder' do
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Cultural Show Page', from: 'Show Page Theme')
      find('body').click
      click_on('Save')
      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      visit "/concern/generic_works/#{work.id}"
      expect(page).to have_css('body.cultural_show.text-show-theme-partial')
      expect(page).to have_css('.text-show-title')
    end

    it 'updates the show theme when the theme is changed' do # rubocop:disable RSpec/ExampleLength
      login_as admin
      visit '/admin/appearance'
      click_link('Themes')
      select('Cultural Show Page', from: 'Show Page Theme')
      find('body').click
      click_on('Save')
      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      visit "/concern/generic_works/#{work.id}"
      expect(page).to have_css('body.cultural_show.text-show-theme-partial')
      expect(page).to have_css('.text-show-title')
      visit '/admin/appearance'
      click_link('Themes')
      select('Default Show Page', from: 'Show Page Theme')
      find('body').click
      click_on('Save')
      site = Site.last
      account.sites << site
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      visit "/concern/generic_works/#{work.id}"
      expect(page).to have_css('body.default_show')
      expect(page).not_to have_css('.text-show-title')
    end

    it 'renders the default partial if the theme partial is missing' do
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      allow_any_instance_of(ApplicationController).to receive(:show_page_theme).and_return("missing_theme")
      visit "/concern/generic_works/#{work.id}"
      expect(page).to have_css('body.missing_theme')
      expect(page).not_to have_css('body.cultural_show.text-show-theme-partial')
    end
  end
end
