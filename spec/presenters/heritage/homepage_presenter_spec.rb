# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heritage::HomepagePresenter, :clean_repo do
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
  let(:response) { instance_double(Blacklight::Solr::Response, total: 7) }
  let(:collections) { [] }
  let(:presenter) do
    described_class.new(
      search_service:,
      response:,
      collections:,
      featured_work_list: FeaturedWorkList.new,
      featured_collection_list: FeaturedCollectionList.new,
      current_ability: ability
    )
  end

  def indexed_work(title, visibility, subject: [], member_of_collection_ids: [])
    saved = Hyrax.persister.save(
      resource: GenericWorkResource.new(title: [title], subject:, member_of_collection_ids:)
    )
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  def indexed_collection(title)
    saved = Hyrax.persister.save(resource: Hyrax::PcdmCollection.new(title: [title]))
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility: 'open')
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  describe '#counts' do
    let(:collections) { [double, double] }

    it 'pairs the readable collection count with the works total' do
      expect(presenter.counts).to eq(collections: 2, works: 7)
    end
  end

  describe '#featured_works' do
    it 'drops a featured work that was public and has since been made private' do
      public_work = indexed_work('Primary Space', 'open')
      private_work = indexed_work('Kiln Yard', 'restricted')
      FeaturedWork.create!(work_id: public_work.id.to_s, order: 0)
      FeaturedWork.create!(work_id: private_work.id.to_s, order: 1)

      featured = presenter.featured_works.map { |work| work.presenter.id }

      expect(featured).to include(public_work.id.to_s)
      expect(featured).not_to include(private_work.id.to_s)
    end
  end

  describe '#featured_collections' do
    let(:featured) { indexed_collection('Harbor Photographs') }
    let(:collections) { [double(id: featured.id.to_s)] }

    it 'keeps a featured collection the visitor can read' do
      FeaturedCollection.create!(collection_id: featured.id.to_s, order: 0)

      expect(presenter.featured_collections.map { |c| c.presenter.id }).to eq([featured.id.to_s])
    end

    it 'drops a featured collection that is no longer readable' do
      hidden = indexed_collection('Restricted Maps')
      FeaturedCollection.create!(collection_id: hidden.id.to_s, order: 0)

      expect(presenter.featured_collections).to be_empty
    end
  end

  describe '#collections' do
    context 'with collections featured' do
      let(:featured) { indexed_collection('Harbor Photographs') }
      let(:collections) { [double(id: featured.id.to_s), double(id: 'not-featured')] }

      it 'shows the curated list rather than every collection' do
        FeaturedCollection.create!(collection_id: featured.id.to_s, order: 0)

        expect(presenter.collections.map(&:id)).to eq([featured.id.to_s])
      end
    end

    context 'with nothing featured' do
      let(:collections) { Array.new(8) { |i| double(id: "col-#{i}") } }

      it 'falls back to the tenant collections, capped at the feature limit' do
        expect(presenter.collections.size).to eq(FeaturedCollection.feature_limit)
      end
    end
  end
end
