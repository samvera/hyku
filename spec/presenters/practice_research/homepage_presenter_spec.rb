# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PracticeResearch::HomepagePresenter, :clean_repo do
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
  let(:presenter) do
    described_class.new(
      search_service:,
      response: instance_double(Blacklight::Solr::Response, total: 7),
      collections: collections,
      featured_work_list: FeaturedWorkList.new,
      featured_collection_list: FeaturedCollectionList.new,
      current_ability: ability
    )
  end
  let(:collections) { [] }

  def indexed_work(title, visibility, subject: [], member_of_collection_ids: [], resource_type: [])
    saved = Hyrax.persister.save(
      resource: GenericWorkResource.new(title: [title], subject:, member_of_collection_ids:, resource_type:)
    )
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
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
    it 'keeps only featured collections present in the readable set' do
      readable = double(id: 'coll-1')
      visible = double('featured', presenter: double(id: 'coll-1'))
      hidden = double('featured', presenter: double(id: 'coll-2'))
      list = instance_double(FeaturedCollectionList, featured_collections: [visible, hidden])
      presenter = described_class.new(search_service:, response: double(total: 0),
                                      collections: [readable], featured_work_list: FeaturedWorkList.new,
                                      featured_collection_list: list, current_ability: ability)

      expect(presenter.featured_collections).to eq([visible])
    end
  end

  describe '#browse_types and #subjects' do
    it 'offers only what the visitor can see' do
      indexed_work('Primary Space', 'open', subject: ['Sculpture'])
      indexed_work('Kiln Yard', 'restricted', subject: ['Ceramics'])

      expect(presenter.browse_types[:field]).to eq('has_model_ssim')
      expect(presenter.browse_types[:items].values).to eq([1])
      expect(presenter.subjects.map(&:value)).to include('Sculpture')
      expect(presenter.subjects.map(&:value)).not_to include('Ceramics')
    end

    it 'offers no types on an empty repository, so the module hides' do
      expect(presenter.browse_types[:items]).to be_empty
    end

    it 'names no more work types than the tile row holds, the largest first' do
      stub_const('PracticeResearch::HomepagePresenter::TYPE_LIMIT', 1)
      2.times { |i| indexed_work("Primary Space #{i}", 'open') }
      image = Hyrax.persister.save(resource: ImageResource.new(title: ['Contact sheet']))
      Hyrax::VisibilityWriter.new(resource: image).assign_access_for(visibility: 'open')
      image.permission_manager.acl.save
      Hyrax.index_adapter.save(resource: image)

      expect(presenter.browse_types[:items]).to eq('GenericWork' => 2)
    end

    context 'when the tenant has removed the facets from the catalog config' do
      let(:config) do
        ::CatalogController.blacklight_config.deep_dup.tap do |dup|
          dup.facet_fields.delete('has_model_ssim')
          dup.facet_fields.delete('subject_sim')
        end
      end
      let(:scope) do
        Struct.new(:blacklight_config, :current_ability, :params, :search_state_class)
              .new(config, ability, {}, nil)
      end
      let(:search_service) do
        Hyrax::SearchService.new(config:, user_params: {}, scope:, current_ability: ability,
                                 search_builder_class: Hyrax::HomepageSearchBuilder)
      end

      it 'offers nothing rather than raising, so the module hides' do
        indexed_work('Primary Space', 'open', subject: ['Sculpture'])

        expect(presenter.browse_types[:items]).to be_empty
        expect(presenter.subjects).to be_empty
      end
    end

    context 'when the tenant has removed only the work type facet' do
      let(:config) do
        ::CatalogController.blacklight_config.deep_dup.tap { |dup| dup.facet_fields.delete('has_model_ssim') }
      end
      let(:scope) do
        Struct.new(:blacklight_config, :current_ability, :params, :search_state_class)
              .new(config, ability, {}, nil)
      end
      let(:search_service) do
        Hyrax::SearchService.new(config:, user_params: {}, scope:, current_ability: ability,
                                 search_builder_class: Hyrax::HomepageSearchBuilder)
      end

      it 'falls back to resource type' do
        indexed_work('Primary Space', 'open', resource_type: ['Poster'])
        indexed_work('Kiln Yard', 'restricted', resource_type: ['Score'])

        expect(presenter.browse_types[:field]).to eq('resource_type_sim')
        expect(presenter.browse_types[:items]).to eq('Poster' => 1)
      end

      it 'names no more types than the tile row holds' do
        stub_const('PracticeResearch::HomepagePresenter::TYPE_LIMIT', 2)
        ['Poster', 'Score', 'Sound'].each_with_index do |type, i|
          indexed_work("Piece #{i}", 'open', resource_type: [type])
        end

        expect(presenter.browse_types[:items].size).to eq 2
      end
    end
  end

  describe '#collection_works_count' do
    it 'counts only the collection members a visitor may see' do
      indexed_work('Site sketchbook', 'open', member_of_collection_ids: ['coll-1'])
      indexed_work('Unreleased maquette', 'restricted', member_of_collection_ids: ['coll-1'])

      expect(presenter.collection_works_count(SolrDocument.new('id' => 'coll-1'))).to eq(1)
    end
  end
end
