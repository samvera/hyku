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

  # Finding the parent's own file sets used to go through `find_child_file_sets`
  # (`find_members(resource:).select(&:file_set?)`), which instantiated every
  # member before discarding the non-file-sets. On an aggregating work that is
  # O(child works) of wasted loading per reindex, several times per save.
  describe 'resolving the parent\'s own file sets', :clean_repo do
    let(:indexer) { Hyrax::Indexers::ResourceIndexer.for(resource: work) }

    context 'when the members are child works' do
      let(:child_work_id) { 'work-member-not-loaded' }
      let(:work) { valkyrie_create(:generic_work_resource, member_ids: [Valkyrie::ID.new(child_work_id)]) }

      before do
        Hyrax::SolrService.add({ 'id' => child_work_id, 'generic_type_sim' => ['Work'] }, commit: true)
      end

      it 'treats them as no file sets at all' do
        expect(indexer.send(:child_file_sets, work)).to be_empty
      end
    end

    context 'when a member really is a file set' do
      let(:file_set) { valkyrie_create(:hyrax_file_set) }
      let(:work) { valkyrie_create(:generic_work_resource, member_ids: [file_set.id]) }

      it 'still finds it' do
        expect(indexer.send(:child_file_sets, work).map(&:id)).to eq([file_set.id])
      end
    end

    context 'with both a child work and a file set, in member order' do
      let(:file_set) { valkyrie_create(:hyrax_file_set) }
      let(:other_file_set) { valkyrie_create(:hyrax_file_set) }
      let(:child_work_id) { 'interleaved-work-member' }
      let(:work) do
        valkyrie_create(:generic_work_resource,
                        member_ids: [other_file_set.id, Valkyrie::ID.new(child_work_id), file_set.id])
      end

      before do
        Hyrax::SolrService.add({ 'id' => child_work_id, 'generic_type_sim' => ['Work'] }, commit: true)
      end

      it 'returns only the file sets, in member order' do
        expect(indexer.send(:child_file_sets, work).map(&:id)).to eq([other_file_set.id, file_set.id])
      end
    end
  end
end
