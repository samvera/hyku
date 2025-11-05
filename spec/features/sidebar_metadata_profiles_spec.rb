# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Dashboard sidebar metadata profiles link', type: :feature, clean: true do
  let(:user) { create(:admin) }

  before do
    login_as user
    allow(ENV).to receive(:fetch).with('HYRAX_FLEXIBLE', false).and_return(true)
  end

  context 'when on a regular tenant' do
    before do
      allow(Site).to receive(:account).and_return(double(search_only?: false))
    end

    scenario 'displays the metadata profiles link' do
      visit hyrax.dashboard_path
      
      within('.sidebar') do
        expect(page).to have_link('Metadata Profiles', href: metadata_profiles_path)
      end
    end
  end

  context 'when on a search-only tenant' do
    before do
      allow(Site).to receive(:account).and_return(double(search_only?: true))
    end

    scenario 'hides the metadata profiles link' do
      visit hyrax.dashboard_path
      
      within('.sidebar') do
        expect(page).not_to have_link('Metadata Profiles')
        expect(page).not_to have_content('Metadata Profiles')
      end
    end
  end

  context 'when HYRAX_FLEXIBLE is disabled' do
    before do
      allow(ENV).to receive(:fetch).with('HYRAX_FLEXIBLE', false).and_return(false)
      allow(Site).to receive(:account).and_return(double(search_only?: false))
    end

    scenario 'hides the metadata profiles link' do
      visit hyrax.dashboard_path
      
      within('.sidebar') do
        expect(page).not_to have_link('Metadata Profiles')
      end
    end
  end

  context 'when user is not an admin' do
    let(:user) { create(:user) }

    before do
      allow(Site).to receive(:account).and_return(double(search_only?: false))
    end

    scenario 'hides the metadata profiles link' do
      visit hyrax.dashboard_path
      
      # Non-admin users shouldn't see admin sidebar sections
      expect(page).not_to have_link('Metadata Profiles')
    end
  end
end