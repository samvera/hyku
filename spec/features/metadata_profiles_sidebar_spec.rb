# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Metadata Profiles Sidebar Navigation', type: :feature, js: true do
  let(:admin_user) { create(:admin) }

  before do
    login_as admin_user, scope: :user
  end

  context 'with flexible metadata enabled' do
    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
    end

    context 'for regular (non-search) tenants' do
      before do
        allow(Site.account).to receive(:search_only?).and_return(false)
      end

      it 'shows the metadata profiles navigation link' do
        visit hyrax.dashboard_path
        expect(page).to have_link('Metadata Profiles')
      end
    end

    context 'for search-only tenants' do
      before do
        # Mock the account to be search-only
        search_account = instance_double("Account")
        allow(search_account).to receive(:search_only?).and_return(true)
        allow(Site).to receive(:account).and_return(search_account)
      end

      it 'does not show the metadata profiles navigation link' do
        visit hyrax.dashboard_path
        expect(page).not_to have_link('Metadata Profiles')
      end
    end
  end

  context 'with flexible metadata disabled' do
    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(false)
    end

    it 'does not show the metadata profiles navigation link' do
      visit hyrax.dashboard_path
      expect(page).not_to have_link('Metadata Profiles')
    end
  end
end
