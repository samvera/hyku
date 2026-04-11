# frozen_string_literal: true

require 'rails_helper'

# Additional VPAT-oriented journeys (sign-in, collection show, work edit).
# Run: bundle exec rspec --tag a11y
RSpec.describe 'VPAT extended path accessibility', :a11y, type: :feature, js: true, clean: true do
  include Warden::Test::Helpers

  context 'user sign-in page' do
    it 'sign-in page primary landmark is axe-clean' do
      visit new_user_session_path(locale: 'en')
      expect(page).to have_css('#user_email')
      expect_hyku_primary_content_axe_clean
    end
  end

  context 'public collection show page' do
    # Real collection + indexer so SolrDocument#read and query_service#find_by match Hyrax abilities.
    let(:collection) do
      FactoryBot.valkyrie_create(:hyku_collection, :public, title: ['Public Accessibility Collection'])
    end

    before do
      solr = Blacklight.default_index.connection
      solr.add(CollectionResourceIndexer.new(resource: collection).to_solr)
      solr.commit
    end

    it 'collection show primary landmark is axe-clean' do
      visit Hyrax::Engine.routes.url_helpers.collection_path(collection.id.to_s, locale: 'en')
      expect(page).to have_content('Public Accessibility Collection')
      expect_hyku_primary_content_axe_clean
    end
  end

  context 'work edit form (default tab)' do
    let(:admin_user) { create(:admin) }
    let(:work) { FactoryBot.valkyrie_create(:generic_work_resource) }

    before do
      create(:admin_group)
      login_as admin_user
    end

    it 'edit work page primary landmark is axe-clean' do
      visit "/concern/generic_works/#{ERB::Util.url_encode(work.id)}/edit?locale=en"
      within '#content-wrapper' do
        expect(page).to have_css('form')
      end
      expect_hyku_primary_content_axe_clean
    end
  end
end
