# frozen_string_literal: true

RSpec.describe HykuIndexing do
  # A parent work aggregates its child works' full text into `all_text_tsimv`.
  # The aggregation reads each child's already-indexed `all_text_tsimv` from
  # Solr rather than re-deriving every child file set's derivative from disk on
  # each reindex (which was O(child works x file sets) and timed out saving
  # works with many children).
  #
  # The child here exists ONLY in Solr - never persisted to Postgres and with no
  # file set/derivative on disk. The old disk/Postgres walk would find nothing
  # for it; the Solr read picks it up. A passing assertion therefore proves the
  # aggregation source, not merely that some text was indexed.
  describe 'child work full-text aggregation', :clean_repo do
    let(:child_id) { 'child-from-solr-only' }
    let(:work) { valkyrie_create(:generic_work_resource, member_ids: [Valkyrie::ID.new(child_id)]) }

    before do
      Hyrax::SolrService.add({ 'id' => child_id,
                               'all_text_tsimv' => ['needle from child derivative'],
                               'generic_type_sim' => ['Work'] }, commit: true)
    end

    it 'indexes child works\' all_text from the Solr index' do
      expect(work.to_solr['all_text_tsimv']).to include('needle from child derivative')
    end
  end
end
