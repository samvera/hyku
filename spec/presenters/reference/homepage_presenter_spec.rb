# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reference::HomepagePresenter do
  let(:ability) { ::Ability.new(nil) }
  let(:config) do
    ::CatalogController.blacklight_config.deep_dup.tap do |dup|
      dup.add_facet_field('subject_label_sim') unless dup.facet_fields.key?('subject_label_sim')
    end
  end
  let(:search_service) { instance_double(Hyrax::SearchService, blacklight_config: config) }
  let(:presenter) do
    described_class.new(search_service:, response: instance_double(Blacklight::Solr::Response, total: 0),
                        collections: [], featured_work_list: FeaturedWorkList.new,
                        featured_collection_list: FeaturedCollectionList.new, current_ability: ability)
  end

  describe '#browse_columns' do
    before do
      allow(presenter).to receive(:facet_items) { |field, _params| [double('item', value: field, hits: 1)] }
    end

    it 'browses a property through its label facet when the catalog registers one' do
      expect(presenter.browse_columns.find { |column| column[:key] == :subjects }[:field]).to eq('subject_label_sim')
    end

    it 'keeps a facet that has no label facet' do
      expect(presenter.browse_columns.find { |column| column[:key] == :collections }[:field]).to eq('member_of_collections_ssim')
    end
  end
end
