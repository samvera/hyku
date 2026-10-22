# frozen_string_literal: true

require 'rails_helper'

# Manual Test Plan: "Homepage" (tenant homepage, default theme: app/views/hyrax/homepage).
# Language picker and static page links: spec/features/ui_ux_and_static_pages_spec.rb.
RSpec.describe 'Homepage', type: :feature, clean: true, flexible: :either do
  def public_work(title)
    FactoryBot.valkyrie_create(:generic_work_resource, visibility_setting: 'open', title: [title])
  end

  def private_work(title)
    FactoryBot.valkyrie_create(:generic_work_resource, visibility_setting: 'restricted', title: [title])
  end

  describe 'login and account name' do
    it 'directs a visitor from Login to the Log in form' do
      visit '/'
      within('#user_utility_links') { click_link 'Login' }

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
      expect(page).to have_field('Email')
      expect(page).to have_field('Password')
    end

    it "shows a signed-in user's display name instead of Login" do
      login_as create(:user, email: 'named.person@example.com', display_name: 'Nadia Named'), scope: :user
      visit '/'

      within('#user_utility_links') do
        expect(page).to have_css('#navbarDropdown', text: 'Nadia Named')
        expect(page).not_to have_css('#navbarDropdown', text: 'named.person@example.com')
        expect(page).not_to have_link('Login')
      end
    end

    it 'falls back to the email address when the user has no display name' do
      login_as create(:user, email: 'nameless.person@example.com', display_name: nil), scope: :user
      visit '/'

      within('#user_utility_links') do
        expect(page).to have_css('#navbarDropdown', text: 'nameless.person@example.com')
        expect(page).not_to have_link('Login')
      end
    end
  end

  describe 'search bar' do
    it 'searches work metadata and lists only matching works the visitor may see' do
      public_work('Homepage Heron Survey')
      public_work('Unrelated Badger Notes')
      private_work('Homepage Heron Private Draft')
      visit '/'

      fill_in 'search-field-header', with: 'Heron'
      click_button 'search-submit-header'

      expect(page).to have_current_path(%r{/catalog})
      expect(page).to have_css('.search-result-title a', text: 'Homepage Heron Survey')
      expect(page).not_to have_css('.search-result-title a', text: 'Unrelated Badger Notes')
      expect(page).not_to have_css('.search-result-title a', text: 'Homepage Heron Private Draft')
    end

    it 'offers the All / My Works / My Collections scope only when signed in' do
      login_as create(:user), scope: :user
      visit '/'

      within('#search-form-header .dropdown-menu') do
        expect(page).to have_css('a[data-search-option^="/catalog"]', text: /\AAll of /)
        expect(page).to have_css('a[data-search-option^="/dashboard/my/works"]', text: 'My Works')
        expect(page).to have_css('a[data-search-option^="/dashboard/my/collections"]', text: 'My Collections')
      end

      logout
      visit '/'
      expect(page).to have_field('search-field-header')
      expect(page).not_to have_css('#search-form-header .dropdown-menu')
    end

    context 'with javascript', js: true do
      let(:user) { create(:user, roles: [:work_depositor]) }

      it 'searches only my works when My Works is chosen' do
        FactoryBot.valkyrie_create(:generic_work_resource, title: ['Kestrel Mine'], depositor: user.user_key,
                                                           edit_users: [user.user_key])
        public_work('Kestrel Someone Else')
        login_as user, scope: :user
        visit '/'

        find('#search-form-header button.dropdown-toggle').click
        click_link 'My Works'
        fill_in 'search-field-header', with: 'Kestrel'
        click_button 'search-submit-header'

        expect(page).to have_current_path(%r{/dashboard/my/works\?.*q=Kestrel})
        expect(page).to have_link('Kestrel Mine')
        expect(page).not_to have_link('Kestrel Someone Else')
      end

      it 'searches only my collections when My Collections is chosen' do
        FactoryBot.valkyrie_create(:hyku_collection, user:, title: ['Kestrel Collection Mine'])
        FactoryBot.valkyrie_create(:hyku_collection, :public, title: ['Kestrel Collection Theirs'])
        login_as user, scope: :user
        visit '/'

        find('#search-form-header button.dropdown-toggle').click
        click_link 'My Collections'
        fill_in 'search-field-header', with: 'Kestrel'
        click_button 'search-submit-header'

        expect(page).to have_current_path(%r{/dashboard/my/collections\?.*q=Kestrel})
        expect(page).to have_link('Kestrel Collection Mine')
        expect(page).not_to have_link('Kestrel Collection Theirs')
      end
    end
  end

  describe 'Share Your Work' do
    it 'directs a visitor who is not logged in to the Log in form' do
      visit '/'
      within('.home-share-work') { click_link 'Share Your Work' }

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
      expect(page).to have_field('Email')
    end

    # Potential duplicate: spec/features/create_work_spec.rb:19 (logged-in Share Your Work reaches the work form)
    it 'directs a logged-in depositor to the work creation form', js: true do
      FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
      FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
      FactoryBot.create(:depositors_group) unless Hyrax::Group.exists?(name: 'depositors')
      Hyrax::AdminSetCreateService.find_or_create_default_admin_set
      login_as create(:user, roles: [:work_depositor]), scope: :user
      visit '/'

      within('.home-share-work') { click_link 'Share Your Work' }
      within('#worktypes-to-create') do
        first('input[name="payload_concern"]').click
        click_button 'Create work'
      end

      expect(page).to have_current_path(%r{/concern/[a-z_]+/new})
      expect(page).to have_css('form.simple_form[action^="/concern/"]')
    end
  end

  describe 'tabs' do
    let!(:featured) { public_work('Featured Falcon Study') }
    let!(:recent) { public_work('Recent Raven Report') }
    let!(:hidden) { private_work('Private Puffin Draft') }
    let!(:featured_collection) { FactoryBot.valkyrie_create(:hyku_collection, :public, title: ['Featured Fjord Collection']) }
    let!(:unfeatured_collection) { FactoryBot.valkyrie_create(:hyku_collection, :public, title: ['Plain Prairie Collection']) }

    before do
      FeaturedWork.create!(work_id: featured.id.to_s)
      FeaturedCollection.create!(collection_id: featured_collection.id.to_s)
      ContentBlock.featured_researcher = '<p>Dr. Ada Featurington studies owls.</p>'
    end

    # Potential duplicate: spec/features/feature_flag_spec.rb:34 (featured/recent works on the homepage; xdescribe, CI-skipped)
    it 'shows featured works, recent public uploads, featured collections and the featured researcher' do
      visit '/'

      within('#featured_container') do
        expect(page).to have_css('.featured-item', count: 1)
        expect(page).to have_link('Featured Falcon Study')
        expect(page).not_to have_content('Recent Raven Report')
      end
      within('#recently_uploaded') do
        expect(page).to have_css('.recent-item', count: 2)
        expect(page).to have_link('Recent Raven Report')
        expect(page).to have_link('Featured Falcon Study')
        expect(page).not_to have_content('Private Puffin Draft')
      end
      within('#featured_collections') do
        expect(page).to have_link('Featured Fjord Collection')
        expect(page).not_to have_content('Plain Prairie Collection')
      end
      within('#tab-col2-second') { expect(page).to have_content('Dr. Ada Featurington studies owls.') }
    end

    it 'switches between the tabs', js: true do
      visit '/'

      expect(page).to have_link('Featured Falcon Study')
      expect(page).not_to have_link('Recent Raven Report')
      click_link 'Recently Uploaded'
      expect(page).to have_link('Recent Raven Report')
      expect(page).not_to have_content('Private Puffin Draft')
      click_link 'Featured Works'
      expect(page).not_to have_link('Recent Raven Report')

      expect(page).to have_link('Featured Fjord Collection')
      expect(page).not_to have_content('Dr. Ada Featurington studies owls.')
      click_link 'Featured Researcher'
      expect(page).to have_content('Dr. Ada Featurington studies owls.')
      expect(page).not_to have_link('Featured Fjord Collection')
      click_link 'Explore Collections'
      expect(page).to have_link('Featured Fjord Collection')
    end

    it 'lists all collections from View all collections' do
      visit '/'
      click_link 'View all collections'

      expect(page).to have_current_path(%r{/catalog\?.*generic_type_sim})
      expect(page).to have_css('.search-result-title a', text: 'Featured Fjord Collection')
      expect(page).to have_css('.search-result-title a', text: 'Plain Prairie Collection')
      expect(page).not_to have_css('.search-result-title a', text: 'Recent Raven Report')
    end
  end
end
