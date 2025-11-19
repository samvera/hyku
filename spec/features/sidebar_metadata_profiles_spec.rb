# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Dashboard sidebar metadata profiles link', type: :feature, clean: true do
  let(:user) { create(:admin) }

  before do
    login_as user
    allow(ENV).to receive(:fetch) do |key, default|
      ENV[key] || default
    end
  end

  after(:each) do
    # Reset ENV and reload routes after each test to avoid leaking state
    ENV['HYRAX_FLEXIBLE'] = nil
    Rails.application.reload_routes!
  end

  context 'when HYRAX_FLEXIBLE is enabled' do
    before do
      ENV['HYRAX_FLEXIBLE'] = 'true'
      Hyrax.config.flexible = true # Ensure Hyrax config is set
      Rails.application.reload_routes!
      allow(Site).to receive(:account).and_return(double(search_only?: false))
    end

    scenario 'displays the metadata profiles link' do
      visit hyrax.dashboard_path

      within('.sidebar') do
        expect(page).to have_link(I18n.t('hyrax.admin.sidebar.metadata_profiles'), href: /\/metadata_profiles/)
      end
    end
  end

  context 'when HYRAX_FLEXIBLE is disabled' do
    before do
      ENV['HYRAX_FLEXIBLE'] = 'false'
      Rails.application.reload_routes!
      allow(Site).to receive(:account).and_return(double(search_only?: false))
    end

    scenario 'hides the metadata profiles link' do
      visit hyrax.dashboard_path

      within('.sidebar') do
        expect(page).not_to have_link(I18n.t('hyrax.admin.sidebar.metadata_profiles'))
      end
    end
  end

  context 'when on a search-only tenant' do
    before do
      ENV['HYRAX_FLEXIBLE'] = 'true'
      Rails.application.reload_routes!
      allow(Site).to receive(:account).and_return(double(search_only?: true))
    end

    scenario 'hides the metadata profiles link' do
      visit hyrax.dashboard_path

      within('.sidebar') do
        expect(page).not_to have_link(I18n.t('hyrax.admin.sidebar.metadata_profiles'))
        expect(page).not_to have_content('Metadata Profiles')
      end
    end
  end

  context 'when user is not an admin' do
    let(:user) { create(:user) }

    before do
      ENV['HYRAX_FLEXIBLE'] = 'true'
      Hyrax.config.flexible = true # Ensure Hyrax config is set
      Rails.application.reload_routes!
      allow(Site).to receive(:account).and_return(double(search_only?: false))
    end

    scenario 'hides the metadata profiles link' do
      visit hyrax.dashboard_path

      expect(page).not_to have_link(I18n.t('hyrax.admin.sidebar.metadata_profiles'))
    end
  end
end