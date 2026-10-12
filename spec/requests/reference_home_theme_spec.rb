# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'reference home theme', type: :request, singletenant: true, clean_repo: true do
  def indexed(resource, visibility = 'open')
    saved = Hyrax.persister.save(resource:)
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  def indexed_work(title, visibility = 'open', **attributes)
    indexed(GenericWorkResource.new(title: [title], **attributes), visibility)
  end

  def hide_facets(*fields)
    config = ::CatalogController.blacklight_config.deep_dup
    fields.each { |field| config.facet_fields.delete(field) }
    allow(::CatalogController).to receive(:blacklight_config).and_return(config)
    allow_any_instance_of(Hyrax::HomepageController).to receive(:blacklight_config).and_return(config)
  end

  def home
    get root_path
    Nokogiri::HTML(response.body)
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return('reference')
  end

  describe 'featured works' do
    let!(:public_work) { indexed_work('Field notes on tidal marshes') }

    before { FeaturedWork.create!(work_id: public_work.id.to_s, order: 0) }

    it 'renders the ones a visitor may read' do
      grid = home.at_css('.ref-featured-works .ref-work-grid')

      expect(grid.css('.ref-work').size).to eq(1)
      expect(grid.text).to include('Field notes on tidal marshes')
    end

    it 'never renders a featured work the visitor cannot read' do
      private_work = indexed_work('Embargoed survey', 'restricted')
      FeaturedWork.create!(work_id: private_work.id.to_s, order: 1)

      doc = home

      expect(response.body).not_to include('Embargoed survey')
      expect(doc.css('.ref-featured-works .ref-work').size).to eq(1)
    end

    it 'hides the section when the tenant turns featured works off' do
      allow(Flipflop).to receive(:show_featured_works?).and_return(false)

      expect(home.at_css('.ref-featured-works')).to be_nil
    end
  end

  describe 'featured collections' do
    let!(:collection) { indexed(Hyrax::PcdmCollection.new(title: ['Coastal Surveys'])) }

    before { FeaturedCollection.create!(collection_id: collection.id.to_s, order: 0) }

    it 'lists them for a screen reader, with a count of the works a visitor may see' do
      indexed_work('Tide table, 1912', 'open', member_of_collection_ids: [collection.id])
      indexed_work('Sealed appendix', 'restricted', member_of_collection_ids: [collection.id])

      list = home.at_css('.ref-featured-collections .ref-collection-list')

      expect(list.name).to eq('ul')
      expect(list.css('> li > .ref-collection-row').size).to eq(1)
      expect(list.at_css('.ref-collection-title').text).to include('Coastal Surveys')
      expect(list.at_css('.ref-collection-count').text.strip).to eq('1 work')
    end

    it 'never renders a featured collection the visitor cannot read' do
      private_collection = indexed(Hyrax::PcdmCollection.new(title: ['Restricted accessions']), 'restricted')
      FeaturedCollection.create!(collection_id: private_collection.id.to_s, order: 1)

      doc = home

      expect(response.body).not_to include('Restricted accessions')
      expect(doc.css('.ref-featured-collections .ref-collection-row').size).to eq(1)
    end
  end

  describe 'the browse band' do
    it 'caps a column at five values and offers the rest behind the facet modal' do
      6.times { |n| indexed_work("Survey #{n}", 'open', subject: ["Subject #{n}"]) }

      column = home.at_css('.ref-browse-column')

      expect(column.css('.ref-browse-value').size).to eq(5)
      expect(column.at_css('.ref-browse-all')['data-blacklight-modal']).to eq('trigger')
    end

    it 'leaves out the modal link when the facet has nothing more to show' do
      indexed_work('Single survey', 'open', subject: ['Estuaries'])

      column = home.at_css('.ref-browse-column')

      expect(column.css('.ref-browse-value').size).to eq(1)
      expect(column.at_css('.ref-browse-all')).to be_nil
    end

    it 'drops a column whose facet the tenant removed rather than raising' do
      indexed_work('Single survey', 'open', subject: ['Estuaries'], publisher: ['Coast Survey Office'])
      hide_facets('subject_sim')

      doc = home

      expect(response).to have_http_status(:ok)
      labels = doc.css('.ref-browse-label').map { |label| label.text.strip }
      expect(labels).to include('Publisher')
      expect(labels).not_to include('Subject')
    end

    it 'hides the band when the tenant removed every axis it browses' do
      indexed_work('Single survey', 'open', subject: ['Estuaries'])
      hide_facets('subject_sim', 'creator_sim', 'member_of_collections_ssim', 'publisher_sim')

      doc = home

      expect(response).to have_http_status(:ok)
      expect(doc.at_css('.ref-browse')).to be_nil
    end
  end
end
