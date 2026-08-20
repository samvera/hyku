# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScreeningRoom::HomepagePresenter, :clean_repo do
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
  let(:collections) { [] }
  let(:presenter) { build_presenter }

  def build_presenter(**overrides)
    described_class.new(
      **{ search_service:,
          response: instance_double(Blacklight::Solr::Response, total: 0),
          collections:,
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

  def indexed_collection(title, visibility = 'open')
    saved = Hyrax.persister.save(resource: Hyrax::PcdmCollection.new(title: [title]))
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  def indexed_file_set(title, visibility)
    saved = Hyrax.persister.save(resource: Hyrax::FileSet.new(title: [title]))
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  describe '#spotlight_works' do
    it 'drops a featured work the visitor cannot read' do
      public_work = indexed_work('Harbor at dusk', 'open')
      private_work = indexed_work('Unreleased reel', 'restricted')
      FeaturedWork.create!(work_id: public_work.id.to_s, order: 0)
      FeaturedWork.create!(work_id: private_work.id.to_s, order: 1)

      expect(presenter.spotlight_works.map(&:id)).to eq([public_work.id.to_s])
    end

    it 'is empty when nothing is featured' do
      expect(presenter.spotlight_works).to eq([])
    end
  end

  describe '#representative_for' do
    it 'builds a presenter for a representative the visitor can read' do
      file_set = indexed_file_set('reel.mp4', 'open')
      work = indexed_work('Harbor at dusk', 'open', representative_id: file_set.id)
      FeaturedWork.create!(work_id: work.id.to_s, order: 0)

      representative = presenter.representative_for(presenter.spotlight_works.first)

      expect(representative).to be_a(Hyrax::FileSetPresenter)
      expect(representative.id).to eq(file_set.id.to_s)
    end

    it 'returns nothing for a representative the visitor cannot read' do
      file_set = indexed_file_set('embargoed.mp4', 'restricted')
      work = indexed_work('Harbor at dusk', 'open', representative_id: file_set.id)
      FeaturedWork.create!(work_id: work.id.to_s, order: 0)

      expect(presenter.representative_for(presenter.spotlight_works.first)).to be_nil
    end

    it 'returns nothing when the work has no representative' do
      work = indexed_work('Metadata only', 'open')
      FeaturedWork.create!(work_id: work.id.to_s, order: 0)

      expect(presenter.representative_for(presenter.spotlight_works.first)).to be_nil
    end
  end

  describe '#collections' do
    it 'falls back to the collections the controller loaded' do
      documents = [SolrDocument.new('id' => 'c1'), SolrDocument.new('id' => 'c2')]
      cards = build_presenter(collections: documents).collections

      expect(cards.map(&:id)).to eq(%w[c1 c2])
    end

    it 'caps the list at the featured collection limit' do
      documents = Array.new(FeaturedCollection.feature_limit + 3) { |n| SolrDocument.new('id' => "c#{n}") }
      cards = build_presenter(collections: documents).collections

      expect(cards.size).to eq(FeaturedCollection.feature_limit)
    end

    it 'drops a featured collection the visitor cannot read' do
      readable = SolrDocument.new('id' => 'readable')
      featured = [double(presenter: double(id: 'hidden', solr_document: SolrDocument.new('id' => 'hidden'))),
                  double(presenter: double(id: 'readable', solr_document: readable))]
      list = instance_double(FeaturedCollectionList, featured_collections: featured, empty?: false)
      cards = build_presenter(collections: [readable], featured_collection_list: list).collections

      expect(cards.map(&:id)).to eq(['readable'])
    end
  end

  describe '#collection_works_count' do
    it 'counts only the works the visitor can read' do
      collection = indexed_collection('Mission Audio')
      indexed_work('Public reel', 'open', member_of_collection_ids: [collection.id])
      indexed_work('Private reel', 'restricted', member_of_collection_ids: [collection.id])

      count = presenter.collection_works_count(SolrDocument.new('id' => collection.id.to_s))

      expect(count).to eq(1)
    end
  end
end
