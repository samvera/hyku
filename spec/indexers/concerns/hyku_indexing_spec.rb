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

  # Under Valkyrie `member_ids` holds both child-work ids and file-set ids. The
  # aggregation hands the whole list to Solr and relies on `fq:
  # generic_type_sim:Work` to return only the child works, so a file-set member
  # must not contribute its text here (the parent's own file sets are handled
  # separately by `extract_text_from_plain_text_files`). This proves the type
  # filter excludes file-set members rather than aggregating everything.
  describe 'mixed member_ids (child work + file set)', :clean_repo do
    let(:child_work_id) { 'child-work-member' }
    let(:file_set_id) { 'file-set-member' }
    let(:work) do
      valkyrie_create(:generic_work_resource,
                      member_ids: [Valkyrie::ID.new(child_work_id), Valkyrie::ID.new(file_set_id)])
    end

    before do
      Hyrax::SolrService.add({ 'id' => child_work_id,
                               'all_text_tsimv' => ['text from child work'],
                               'generic_type_sim' => ['Work'] }, commit: false)
      Hyrax::SolrService.add({ 'id' => file_set_id,
                               'all_text_tsimv' => ['text from file set'],
                               'generic_type_si' => 'FileSet' }, commit: true)
    end

    it 'aggregates only the child work text, not the file set member' do
      all_text = work.to_solr['all_text_tsimv']

      expect(all_text).to include('text from child work')
      expect(all_text).not_to include('text from file set')
    end
  end
end
