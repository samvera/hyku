# frozen_string_literal: true

RSpec.describe Hyrax::AttachedFilesHelperBehavior, type: :helper do
  describe '#attached_file_set_presenters' do
    let(:form) { double('WorkForm', member_ids: member_ids) }
    let(:query_service) { instance_double(Hyrax::SolrQueryService) }

    # The presenters take the current ability; helper specs have no Warden.
    before { allow(helper).to receive(:current_ability).and_return(Ability.new(nil)) }

    def solr_document(id:, file_set: true)
      instance_double(SolrDocument, id: id, file_set?: file_set)
    end

    context 'when the work has no members' do
      let(:member_ids) { [] }

      it 'returns no presenters' do
        expect(helper.attached_file_set_presenters(form)).to eq([])
      end

      it 'does not query solr, which rejects an empty id list' do
        expect(Hyrax::SolrQueryService).not_to receive(:new)

        helper.attached_file_set_presenters(form)
      end
    end

    context 'when the work has members' do
      let(:member_ids) { ['fs-1', 'fs-2'] }
      let(:documents) { [solr_document(id: 'fs-2'), solr_document(id: 'fs-1')] }

      before do
        allow(Hyrax::SolrQueryService).to receive(:new).and_return(query_service)
        allow(query_service).to receive(:with_ids).with(ids: member_ids).and_return(query_service)
        allow(query_service).to receive(:solr_documents).and_return(documents)
      end

      it 'returns a presenter per attached file set' do
        presenters = helper.attached_file_set_presenters(form)

        expect(presenters).to all(be_a(Hyrax::FileSetPresenter))
      end

      it 'restores the work member order, which solr does not preserve' do
        presenters = helper.attached_file_set_presenters(form)

        expect(presenters.map(&:id)).to eq(['fs-1', 'fs-2'])
      end

      it 'requests enough rows to cover every member' do
        expect(query_service).to receive(:solr_documents).with(rows: 2).and_return(documents)

        helper.attached_file_set_presenters(form)
      end
    end

    context 'when a member is a child work rather than a file set' do
      let(:member_ids) { ['fs-1', 'work-2'] }
      let(:documents) do
        [solr_document(id: 'fs-1'), solr_document(id: 'work-2', file_set: false)]
      end

      before do
        allow(Hyrax::SolrQueryService).to receive(:new).and_return(query_service)
        allow(query_service).to receive(:with_ids).and_return(query_service)
        allow(query_service).to receive(:solr_documents).and_return(documents)
      end

      it 'lists only the file sets' do
        presenters = helper.attached_file_set_presenters(form)

        expect(presenters.map(&:id)).to eq(['fs-1'])
      end
    end

    context 'when the form has no member_ids at all' do
      let(:form) { double('WorkForm') }

      it 'returns no presenters' do
        expect(helper.attached_file_set_presenters(form)).to eq([])
      end
    end
  end
end
