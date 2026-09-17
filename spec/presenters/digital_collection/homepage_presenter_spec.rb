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

  def indexed_work(title, visibility, **attributes)
    saved = Hyrax.persister.save(resource: GenericWorkResource.new(title: [title], **attributes))
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  def indexed_collection(title)
    saved = Hyrax.persister.save(resource: Hyrax::PcdmCollection.new(title: [title], collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id.to_s))
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility: 'open')
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  def featured_list(*ids)
    featured = ids.map do |id|
      document = SolrDocument.new('id' => id, 'title_tesim' => [id.titleize])
      double(presenter: double(id:, solr_document: document))
    end

    instance_double(FeaturedCollectionList, featured_collections: featured, empty?: featured.empty?)
  end

  describe '#browse_collections' do
    it 'orders the access-filtered collections by title regardless of case' do
      documents = [SolrDocument.new('id' => 'b', 'title_tesim' => ['Beta']),
                   SolrDocument.new('id' => 'a', 'title_tesim' => ['alpha']),
                   SolrDocument.new('id' => 'c', 'title_tesim' => ['Gamma'])]

      expect(build_presenter(collections: documents).browse_collections.map(&:id)).to eq(%w[a b c])
    end

    it 'reads only the collections the controller loaded' do
      expect(build_presenter(collections: []).browse_collections).to eq([])
    end
  end

  describe '#browse_works_count' do
    it 'counts only the works a visitor can read, in one query for the band' do
      collection = indexed_collection('Field Recordings')
      indexed_work('Public reel', 'open', member_of_collection_ids: [collection.id])
      indexed_work('Private reel', 'restricted', member_of_collection_ids: [collection.id])
      document = SolrDocument.new('id' => collection.id.to_s)

      presenter = build_presenter(collections: [document])

      expect(presenter.browse_works_count(document)).to eq(1)
    end

    it 'reports nothing for a collection with no readable works' do
      expect(build_presenter.browse_works_count(SolrDocument.new('id' => 'empty'))).to eq(0)
    end
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
