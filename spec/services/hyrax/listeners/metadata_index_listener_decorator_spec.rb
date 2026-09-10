# frozen_string_literal: true

RSpec.describe Hyrax::Listeners::MetadataIndexListenerDecorator, type: :decorator do
  let(:listener) { Hyrax::Listeners::MetadataIndexListener.new }
  let(:file_metadata) { Hyrax::FileMetadata.new }
  let(:account) { FactoryBot.create(:account, skip_file_metadata_solr_indexing: skip) }

  before do
    allow(Account).to receive(:find_by).with(tenant: Apartment::Tenant.current).and_return(account)
  end

  describe '#on_file_metadata_updated' do
    let(:event) { Dry::Events::Event.new('file.metadata.updated', metadata: file_metadata) }

    context 'when the account has not opted in' do
      let(:skip) { false }

      it 'indexes as usual' do
        expect(Hyrax.index_adapter).to receive(:save).with(resource: file_metadata)
        listener.on_file_metadata_updated(event)
      end
    end

    context 'when the account has opted in' do
      let(:skip) { true }

      it 'skips indexing' do
        expect(Hyrax.index_adapter).not_to receive(:save)
        listener.on_file_metadata_updated(event)
      end
    end
  end

  describe '#on_file_metadata_deleted' do
    let(:event) { Dry::Events::Event.new('file.metadata.deleted', metadata: file_metadata) }
    let(:skip) { true }

    it 'skips the Solr delete when opted in' do
      expect(Hyrax.index_adapter).not_to receive(:delete)
      listener.on_file_metadata_deleted(event)
    end
  end
end
