# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'practice research home theme', type: :request, singletenant: true, clean_repo: true do
  let!(:collection) do
    saved = Hyrax.persister.save(resource: Hyrax::PcdmCollection.new(title: ['Studio Practice']))
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility: 'open')
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  before do
    [['Site sketchbook', 'open'], ['Unreleased maquette', 'restricted']].each do |title, visibility|
      saved = Hyrax.persister.save(
        resource: GenericWorkResource.new(title: [title], member_of_collection_ids: [collection.id])
      )
      Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
      saved.permission_manager.acl.save
      Hyrax.index_adapter.save(resource: saved)
    end
    FeaturedCollection.create!(collection_id: collection.id.to_s, order: 0)
    allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return('practice_research')
  end

  it 'counts only the collection members a visitor may see' do
    get root_path

    card = Nokogiri::HTML(response.body).at_css('.pr-portfolio')
    expect(card.text).to include('Studio Practice')
    expect(card.at_css('.pr-eyebrow-count').text.strip).to eq('1 work')
  end

  it 'lists the featured collections for a screen reader' do
    get root_path

    grid = Nokogiri::HTML(response.body).at_css('.pr-portfolio-grid')
    expect(grid.name).to eq 'ul'
    expect(grid.css('> li').size).to eq 1
    expect(grid.at_css('> li > .pr-portfolio')).to be_present
  end

  describe 'the browse band' do
    def browse_band
      get root_path
      Nokogiri::HTML(response.body)
    end

    def hide_facets(*fields)
      config = ::CatalogController.blacklight_config.deep_dup
      fields.each { |field| config.facet_fields.delete(field) }
      allow(::CatalogController).to receive(:blacklight_config).and_return(config)
      allow_any_instance_of(Hyrax::HomepageController).to receive(:blacklight_config).and_return(config)
    end

    it 'browses work type when the tenant keeps that facet' do
      doc = browse_band

      expect(doc.css('.pr-browse .pr-section-title').map { |title| title.text.strip })
        .to include('Browse by work type')
      expect(doc.at_css('.pr-type-tile')['href']).to include('has_model_ssim')
    end

    it 'falls back to resource type when the tenant hides work type' do
      hide_facets('has_model_ssim')
      saved = Hyrax.persister.save(resource: GenericWorkResource.new(title: ['Poster study'], resource_type: ['Poster']))
      Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility: 'open')
      saved.permission_manager.acl.save
      Hyrax.index_adapter.save(resource: saved)

      doc = browse_band

      expect(doc.css('.pr-browse .pr-section-title').map { |title| title.text.strip })
        .to include('Browse by resource type')
      expect(doc.at_css('.pr-type-tile')['href']).to include('resource_type_sim')
    end

    it 'hides the band when the tenant hides both axes and subjects' do
      hide_facets('has_model_ssim', 'resource_type_sim', 'subject_sim')

      doc = browse_band

      expect(response).to have_http_status(:ok)
      expect(doc.at_css('.pr-browse')).to be_nil
    end
  end
end
