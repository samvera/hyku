# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Metadata Profiles Access Control', type: :feature do
  let(:admin_user) { create(:admin) }

  before do
    login_as admin_user, scope: :user
  end

  context 'when HYRAX_FLEXIBLE is enabled' do
    before do
      stub_const('ENV', ENV.to_hash.merge('HYRAX_FLEXIBLE' => 'true'))
    end

    context 'for search-only tenants' do
      before do
        # Mock the account to be search-only
        search_account = instance_double("Account")
        allow(search_account).to receive(:search_only?).and_return(true)
        allow(Site).to receive(:account).and_return(search_account)
      end

      it 'redirects direct URL access to metadata profiles to access denied page' do
        visit '/metadata_profiles'
        
        expect(current_path).to eq('/access_denied')
        expect(page).to have_content('Metadata Profiles Access Denied')
        expect(page).to have_content('Access to metadata profiles is not available for search-only tenants.')
      end

      it 'redirects metadata profiles sub-paths to access denied page' do
        visit '/metadata_profiles/new'
        
        expect(current_path).to eq('/access_denied')
        expect(page).to have_content('Metadata Profiles Access Denied')
      end

      it 'redirects metadata profiles with ID to access denied page' do
        visit '/metadata_profiles/123'
        
        expect(current_path).to eq('/access_denied')
        expect(page).to have_content('Metadata Profiles Access Denied')
      end

      it 'preserves the metadata_profiles reason parameter' do
        visit '/metadata_profiles'
        
        expect(current_url).to include('reason=metadata_profiles')
      end

      it 'allows navigation from access denied page back to dashboard' do
        visit '/metadata_profiles'
        
        expect(page).to have_link('Return to Dashboard', href: '/dashboard')
        click_link 'Return to Dashboard'
        
        expect(current_path).to eq('/dashboard')
      end

      it 'allows navigation from access denied page to home' do
        visit '/metadata_profiles'
        
        # Should be redirected to access denied page and contain some navigation
        expect(page).to have_content('Access Denied') 
        expect(page).to have_link('Go to Home Page')
      end

      it 'does not block other admin routes' do
        visit hyrax.dashboard_path
        expect(page).to have_http_status(:success)
        expect(page).not_to have_content('Access Denied')
      end
    end

    context 'for regular (non-search) tenants' do
      before do
        # Mock the account to be regular (not search-only)
        regular_account = instance_double("Account")
        allow(regular_account).to receive(:search_only?).and_return(false)
        allow(Site).to receive(:account).and_return(regular_account)
      end

      it 'allows access to metadata profiles' do
        # Note: This might still fail due to missing routes/controllers
        # but it should not be blocked by our middleware
        visit '/metadata_profiles'
        
        # Should not be redirected to access denied
        expect(current_path).not_to eq('/access_denied')
        expect(page).not_to have_content('Metadata Profiles Access Denied')
      end
    end
  end

  context 'when HYRAX_FLEXIBLE is disabled' do
    before do
      stub_const('ENV', ENV.to_hash.merge('HYRAX_FLEXIBLE' => 'false'))
    end

    context 'for search-only tenants' do
      before do
        search_account = instance_double("Account")
        allow(search_account).to receive(:search_only?).and_return(true)
        allow(Site).to receive(:account).and_return(search_account)
      end

      it 'does not block access to metadata profiles when HYRAX_FLEXIBLE is disabled' do
        visit '/metadata_profiles'
        
        # Should not be blocked by middleware when HYRAX_FLEXIBLE=false
        expect(current_path).not_to eq('/access_denied')
        expect(page).not_to have_content('Metadata Profiles Access Denied')
      end
    end
  end
end