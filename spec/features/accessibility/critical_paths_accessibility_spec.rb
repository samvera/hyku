# frozen_string_literal: true

require 'rails_helper'

# VPAT-oriented regression scans (axe-core). Run only: bundle exec rspec --tag a11y
RSpec.describe 'VPAT critical path accessibility', :a11y, type: :feature, js: true, clean: true do
  include Warden::Test::Helpers

  context 'catalog search (public work in index)' do
    let(:fake_solr_document) do
      {
        'has_model_ssim': ['GenericWork'],
        id: SecureRandom.uuid,
        'title_tesim': ['Public GenericWork'],
        'admin_set_tesim': ['Default Admin Set'],
        'suppressed_bsi': false,
        'read_access_group_ssim': ['public'],
        'edit_access_group_ssim': ['admin'],
        'edit_access_person_ssim': ['fake@example.com'],
        'visibility_ssi': 'open'
      }
    end

    before do
      solr = Blacklight.default_index.connection
      solr.add(fake_solr_document)
      solr.commit
    end

    it 'catalog index primary landmark is axe-clean' do
      visit '/catalog'
      expect(page).to have_content('Public GenericWork')
      expect_hyku_primary_content_axe_clean
    end
  end

  context "public work show page" do
    let(:id) { SecureRandom.uuid }
    let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    let(:work) { double(GenericWork, id: id, visibility: visibility) }
    let(:fake_solr_document) do
      {
        'has_model_ssim': ['GenericWork'],
        id: id,
        'title_tesim': ['Public GenericWork'],
        'admin_set_tesim': ['Default Admin Set'],
        'suppressed_bsi': false,
        'read_access_group_ssim': ['public'],
        'edit_access_group_ssim': ['admin'],
        'edit_access_person_ssim': ['fake@example.com'],
        'visibility_ssi': visibility
      }
    end

    before do
      solr = Blacklight.default_index.connection
      solr.add(fake_solr_document)
      solr.commit
      allow(Hyrax.query_service).to receive(:find_by).with(id: id).and_return(work)
    end

    it 'work show primary landmark is axe-clean' do
      visit "/concern/generic_works/#{id}"
      expect(page).to have_content('Public GenericWork')
      expect_hyku_primary_content_axe_clean
    end
  end

  context 'admin dashboard' do
    let(:user) { create(:admin) }

    before { login_as(user, scope: :user) }

    it 'dashboard primary landmark is axe-clean' do
      visit Hyrax::Engine.routes.url_helpers.dashboard_path
      expect(page).to have_css('.sidebar')
      expect_hyku_primary_content_axe_clean
    end
  end

  context 'site labels (admin settings form)' do
    let(:user) { create(:admin) }

    before { login_as(user, scope: :user) }

    it 'labels form primary landmark is axe-clean' do
      visit edit_site_labels_path
      expect(page).to have_field('Application name')
      expect_hyku_primary_content_axe_clean
    end
  end

  context 'deposit workflow entry' do
    let(:user) { create(:user, roles: [:work_depositor]) }

    before do
      create(:registered_group)
      create(:admin_group)
      create(:editors_group)
      create(:depositors_group)
      Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id
      login_as user, scope: :user
    end

    it 'share your work path primary landmark is axe-clean' do
      visit '/'
      click_link 'Share Your Work'
      expect(page).to have_button('Create work')
      expect_hyku_primary_content_axe_clean
    end
  end

  context 'when multitenant splash is shown', multitenant: true do
    around do |example|
      original = ENV['HYKU_ADMIN_ONLY_TENANT_CREATION']
      ENV['HYKU_ADMIN_ONLY_TENANT_CREATION'] = "true"
      default_host = Capybara.default_host
      Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
      example.run
      Capybara.default_host = default_host
      ENV['HYKU_ADMIN_ONLY_TENANT_CREATION'] = original
    end

    it 'splash primary landmark is axe-clean' do
      visit '/'
      expect(page).to have_link 'Login to get started', href: main_app.new_user_session_path(locale: 'en')
      expect_hyku_primary_content_axe_clean
    end
  end
end
