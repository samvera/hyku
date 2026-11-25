# frozen_string_literal: true

RSpec.describe Hyrax::Dashboard::NestedCollectionsSearchBuilder do
  let(:scope) { double(current_ability: Ability.new(create(:user)), blacklight_config: CatalogController.blacklight_config, search_state_class: nil) }
  let(:collection) { FactoryBot.valkyrie_create(:hyku_collection) }
  let(:solr_parameters) { {} }

  %i[as_parent as_child].each do |nest_direction|
    it "keeps both graph filters out of the filter cache #{nest_direction}" do
      builder = described_class.new(scope:, access: :read, collection:, nest_direction:)

      builder.show_only_other_collections_of_the_same_collection_type(solr_parameters)

      graph_filters = solr_parameters[:fq].grep(/\{!graph /)
      expect(graph_filters.size).to eq(2)
      expect(graph_filters).to all(start_with('-{!graph cache=false '))
    end
  end

  it 'excludes the parents and children of the collection, limited to one level on the nesting side' do
    builder = described_class.new(scope:, access: :read, collection:, nest_direction: :as_parent)

    builder.show_only_other_collections_of_the_same_collection_type(solr_parameters)

    expect(solr_parameters[:fq]).to include(
      "-{!graph cache=false from=id to=member_of_collection_ids_ssim maxDepth=1}id:#{collection.id}",
      "-{!graph cache=false to=id from=member_of_collection_ids_ssim}id:#{collection.id}"
    )
  end
end
