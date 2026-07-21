# frozen_string_literal: true

RSpec.describe Bulkrax::ImportBehaviorDecorator do
  describe '#build_for_importer' do
    # The entry must be persisted: recording a per-entry failure creates an
    # associated Bulkrax::Status, which requires a saved parent.
    let(:entry) { create(:bulkrax_oer_csv_entry, importerexporter: importer, parsed_metadata: nil) }
    let(:importer) { create(:bulkrax_importer_oer_csv) }
    let(:account) { build(:account, settings:) }
    let(:settings) { { file_size_limit: '1000' } }
    # world.png is 4218 bytes with content type image/png
    let(:file_path) { File.join(file_fixture_path, 'images', 'world.png') }
    let(:factory) { instance_double(Bulkrax::ValkyrieObjectFactory, run!: nil) }

    before do
      Bulkrax::ImporterRun.create!(importer:)
      allow(Site).to receive(:account).and_return(account)
      allow(entry).to receive(:factory_class).and_return(nil)
      allow(entry).to receive(:validate_work_type!)
      allow(entry).to receive(:build_metadata) do
        entry.parsed_metadata = { 'file' => [file_path] }
      end
      allow(entry).to receive(:collections_created?).and_return(true)
      allow(entry).to receive(:factory).and_return(factory)
    end

    context 'when a file exceeds the tenant file size limit' do
      it 'does not raise and does not run the object factory' do
        expect { entry.build_for_importer }.not_to raise_error
        expect(factory).not_to have_received(:run!)
      end

      it 'records a readable failure on the entry alone' do
        entry.build_for_importer

        expect(entry.current_status.status_message).to eq('Failed')
        expect(entry.current_status.error_message).to include('file size limit')
      end
    end

    context 'when a file content type is not accepted by the tenant' do
      let(:settings) { { allowed_content_types: 'application/pdf' } }

      it 'records a readable failure on the entry alone' do
        entry.build_for_importer

        expect(entry.current_status.status_message).to eq('Failed')
        expect(entry.current_status.error_message).to include('not accepted')
      end
    end

    context 'when the files would cross the tenant storage ceiling' do
      let(:settings) { { storage_limit: '10000' } }

      before { allow(UploadLimitsService).to receive(:current_storage_usage).and_return(10_000) }

      it 'records a readable failure on the entry alone' do
        entry.build_for_importer

        expect(entry.current_status.status_message).to eq('Failed')
        expect(entry.current_status.error_message).to include('storage limit')
      end
    end

    context 'when the files satisfy the tenant limits' do
      let(:settings) { { file_size_limit: '1000000' } }

      it 'runs the object factory' do
        entry.build_for_importer

        expect(factory).to have_received(:run!)
      end
    end
  end
end
