# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DigitalCollection::HomepagePresenter, :clean_repo do
  let(:ability) { ::Ability.new(nil) }
  let(:scope) do
    Struct.new(:blacklight_config, :current_ability, :params, :search_state_class)
          .new(::CatalogController.blacklight_config, ability, {}, nil)
  end
  let(:search_service) do
    Hyrax::SearchService.new(
      config: ::CatalogController.blacklight_config,
      user_params: {},
      scope:,
      current_ability: ability,
      search_builder_class: Hyrax::HomepageSearchBuilder
    )
  end

  def build_presenter(**overrides)
    described_class.new(
      **{ search_service:,
          response: instance_double(Blacklight::Solr::Response, total: 0),
          collections: [],
          featured_work_list: FeaturedWorkList.new,
          featured_collection_list: FeaturedCollectionList.new,
          current_ability: ability }.merge(overrides)
    )
  end

  def featured_list(*ids)
    featured = ids.map do |id|
      document = SolrDocument.new('id' => id, 'title_tesim' => [id.titleize])
      double(presenter: double(id:, solr_document: document))
    end

    instance_double(FeaturedCollectionList, featured_collections: featured, empty?: featured.empty?)
  end

  describe '#hero_collections' do
    it 'keeps a featured collection the visitor can read' do
      readable = SolrDocument.new('id' => 'readable')

      slides = build_presenter(collections: [readable],
                               featured_collection_list: featured_list('readable')).hero_collections

      expect(slides.map(&:id)).to eq(['readable'])
    end

    it 'drops a featured collection the visitor cannot read' do
      readable = SolrDocument.new('id' => 'readable')

      slides = build_presenter(collections: [readable],
                               featured_collection_list: featured_list('hidden', 'readable')).hero_collections

      expect(slides.map(&:id)).to eq(['readable'])
    end

    it 'renders nothing when every featured collection is unreadable' do
      slides = build_presenter(collections: [],
                               featured_collection_list: featured_list('hidden')).hero_collections

      expect(slides).to be_empty
    end

    it 'builds each slide with the visitor ability rather than the featured list ability' do
      readable = SolrDocument.new('id' => 'readable')

      slides = build_presenter(collections: [readable],
                               featured_collection_list: featured_list('readable')).hero_collections

      expect(slides.map(&:current_ability)).to eq([ability])
    end
  end
end
