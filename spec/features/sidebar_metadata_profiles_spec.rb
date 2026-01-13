
# frozen_string_literal: true
ENV['HYRAX_FLEXIBLE'] = 'true'
require 'rails_helper'

RSpec.feature 'Dashboard sidebar metadata profiles link', type: :feature, clean: true do
  let(:user) { create(:admin) }

  before do
    allow(ENV).to receive(:fetch) do |key, default|
      ENV[key] || default
    end
  end



  context 'when HYRAX_FLEXIBLE is enabled' do
    before do
      login_as user
      allow(Site).to receive(:account).and_return(double(search_only?: false))
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:current_ability).and_return(Ability.new(user))
      allow_any_instance_of(Ability).to receive(:can?).and_call_original
      allow_any_instance_of(Ability).to receive(:can?).with(:manage, Hyrax::FlexibleSchema).and_return(true)
    end

    scenario 'displays the metadata profiles link' do
      visit hyrax.dashboard_path
      begin
        expect(page).to have_link(I18n.t('hyrax.admin.sidebar.metadata_profiles'), href: /\/metadata_profiles/)
      rescue RSpec::Expectations::ExpectationNotMetError => e
        puts page.body
        raise e
      end
    end
  end

  context 'when HYRAX_FLEXIBLE is disabled' do
    before do
      login_as user
      allow(Site).to receive(:account).and_return(double(search_only?: false))
      allow(Hyrax.config).to receive(:flexible?).and_return(false)
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
      login_as user
      allow(Site).to receive(:account).and_return(double(search_only?: true))
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
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
      login_as user
      allow(Site).to receive(:account).and_return(double(search_only?: false))
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
    end

    scenario 'hides the metadata profiles link' do
      visit hyrax.dashboard_path

      expect(page).not_to have_link(I18n.t('hyrax.admin.sidebar.metadata_profiles'))
    end
  end
end