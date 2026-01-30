# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'a sitemap' do
  let(:xml) { Nokogiri::XML(response.body) }
  let(:locs) { xml.xpath('//xmlns:loc', 'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9').map(&:text) }
  let(:account) { create(:account) }
  let(:work) { create(:work) }
  let(:tenant_user_attributes) { attributes_for(:user) }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account:)
      work
    end

    # Clean Solr before adding test documents to prevent leaky specs
    solr = Blacklight.default_index.connection
    solr.delete_by_query('*:*')
    solr.commit

    solr.add([
               {
                 id: work.id,
                 has_model_ssim: ['GenericWork'],
                 read_access_group_ssim: ['public'],
                 visibility_ssi: 'open'
               },
               {
                 id: collection_id,
                 has_model_ssim: [Hyrax.config.collection_model],
                 read_access_group_ssim: ['public'],
                 visibility_ssi: 'open'
               },
               {
                 id: private_work_id,
                 has_model_ssim: ['GenericWork'],
                 read_access_group_ssim: [],
                 visibility_ssi: 'restricted'
               }
             ])
    solr.commit
  end

  after do
    # Clean up Solr after tests
    solr = Blacklight.default_index.connection
    solr.delete_by_query('*:*')
    solr.commit
    WebMock.enable!
  end

  describe 'GET /sitemap' do
    it 'includes links to sub-sitemaps' do
      get "http://#{account.cname}/sitemap"

      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(%r{application/xml})
      expect(locs.size).to eq(16)
      expect(locs).to include(match(%r{/sitemap/#{collection_sitemap_id}}))
      expect(locs).to include(match(%r{/sitemap/#{work.id[0]}}))
    end
  end
  describe 'GET /sitemap/:id' do
    context 'with a work' do
      it 'generates proper Hyrax URLs for works and collections' do
        get "http://#{account.cname}/sitemap/#{work.id[0]}"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to match(%r{application/xml})
        # Should contain work URL through main_app
        expect(locs).to include(match(%r{/concern/generic_works/#{work.id}}))
      end
      it 'only shows objects that match the index' do
        get "http://#{account.cname}/sitemap/#{work.id[0]}"
        expect(locs.size).to eq(1)
        expect(locs).not_to include(match(%r{/collections/#{collection_id}}))
      end
    end
    context 'with a collection' do
      it 'generates proper Hyrax URLs for works and collections' do
        get "http://#{account.cname}/sitemap/#{collection_sitemap_id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to match(%r{application/xml})
        # Should contain collection URL through hyrax engine
        expect(locs).to include(match(%r{/collections/#{collection_id}}))
      end
    end
    context 'with a private work' do
      it 'does not include it on the show page' do
        get "http://#{account.cname}/sitemap/#{private_work_sitemap_id}"
        expect(locs).not_to include(match(%r{#{private_work_id}}))
      end
    end
  end
end

RSpec.describe 'Sitemap generation', :clean_repo, type: :request do
  context 'with UUIDs as identifiers' do
    let(:work_id) { '8d06fd24-e84c-482b-9505-06a37a34dbe2' }
    let(:collection_id) { 'c0a0cbbd-c7fa-4d5d-b8f6-ad5fddf171fc' }
    let(:private_work_id) { '91d96555-d40f-40e5-9f27-1b20885b066a' }
    let(:public_work_sitemap_id) { work_id[0] }
    let(:collection_sitemap_id) { collection_id[0] }
    let(:private_work_sitemap_id) { private_work_id[0] }

    before { BlacklightDynamicSitemap::Engine.config.hashed_id_field = 'id' }

    it_behaves_like 'a sitemap'
  end
end
