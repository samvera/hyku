# frozen_string_literal: true

RSpec.describe Hyku::IiifSearchDecorator do
  let(:parent_id) { 'parent-work-id' }
  let(:child_id) { 'child-work-id' }
  let(:iiif_config) do
    { object_relation_field: 'is_page_of_ssim', full_text_field: 'all_text_tsimv',
      supported_params: %w[q page], autocomplete_handler: 'iiif_suggest', suggester_name: 'iiifSuggester' }
  end
  let(:parent_document) do
    SolrDocument.new('id' => parent_id, 'descendent_member_ids_ssim' => descendent_ids)
  end
  let(:descendent_ids) { [child_id] }
  let(:params) { { solr_document_id: parent_id, q: 'test' } }
  let(:search) { BlacklightIiifSearch::IiifSearch.new(params, iiif_config, parent_document) }
  let!(:test_strategy) { Flipflop::FeatureSet.current.test! }

  before do
    allow(Hyrax::SolrService).to receive(:query).and_return('response' => { 'docs' => [] })
  end

  after { test_strategy.switch!(:iiif_ranges, false) }

  describe '#solr_params' do
    context 'when iiif_ranges is off' do
      before { test_strategy.switch!(:iiif_ranges, false) }

      it 'does not add descendant IDs to the query' do
        result = search.solr_params
        expect(result[:q]).to include("is_page_of_ssim:\"#{parent_id}\"")
        expect(result[:q]).not_to include(child_id)
      end
    end

    context 'when iiif_ranges is on' do
      before { test_strategy.switch!(:iiif_ranges, true) }

      it 'groups the parent and descendant relation clauses with OR' do
        result = search.solr_params
        expect(result[:q]).to include("(is_page_of_ssim:\"#{parent_id}\" OR is_page_of_ssim:\"#{child_id}\")")
      end

      context 'with multiple descendants' do
        let(:grandchild_id) { 'grandchild-work-id' }
        let(:descendent_ids) { [child_id, grandchild_id] }

        it 'includes all descendant IDs joined with OR' do
          result = search.solr_params
          expect(result[:q]).to include("is_page_of_ssim:\"#{child_id}\" OR is_page_of_ssim:\"#{grandchild_id}\"")
        end
      end

      context 'when descendent_member_ids_ssim includes the parent ID' do
        let(:descendent_ids) { [parent_id, child_id] }

        it 'excludes the parent from the expansion' do
          result = search.solr_params
          expect(result[:q]).to include("is_page_of_ssim:\"#{child_id}\"")
          expect(result[:q].scan("is_page_of_ssim:\"#{parent_id}\"").length).to eq 1
        end
      end

      context 'with no descendent_member_ids_ssim' do
        let(:descendent_ids) { nil }

        it 'does not expand the relation clause' do
          result = search.solr_params
          expect(result[:q]).to include("is_page_of_ssim:\"#{parent_id}\"")
          expect(result[:q]).not_to include(child_id)
        end
      end

      context 'with empty descendent_member_ids_ssim' do
        let(:descendent_ids) { [] }

        it 'does not expand the relation clause' do
          result = search.solr_params
          expect(result[:q]).not_to include(child_id)
        end
      end
    end
  end
end
