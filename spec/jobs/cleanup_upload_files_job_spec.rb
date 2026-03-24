# frozen_string_literal: true

RSpec.describe CleanupUploadFilesJob do
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    clear_enqueued_jobs
  end

  let(:uploads_path) { '/app/samvera/uploads/tenant-abc' }
  let(:tenant) { 'tenant-abc' }
  let(:carrierwave_dir) { "#{uploads_path}/hyrax/uploaded_file/file" }

  context 'when the Carrierwave directory exists' do
    before do
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(carrierwave_dir).and_return(true)
    end

    it 'spawns a CleanupSubDirectoryJob for the Carrierwave directory' do
      expect do
        described_class.perform_now(delete_ingested_after_days: 180, uploads_path: uploads_path, tenant: tenant)
      end.to have_enqueued_job(CleanupSubDirectoryJob)
        .with(
          delete_ingested_after_days: 180,
          directory: carrierwave_dir,
          delete_all_after_days: 730,
          tenant: tenant
        )
    end

    it 'passes delete_all_after_days parameter to child job' do
      expect do
        described_class.perform_now(delete_ingested_after_days: 180,
                                    uploads_path: uploads_path,
                                    delete_all_after_days: 365,
                                    tenant: tenant)
      end.to have_enqueued_job(CleanupSubDirectoryJob)
        .with(
          delete_ingested_after_days: 180,
          directory: carrierwave_dir,
          delete_all_after_days: 365,
          tenant: tenant
        )
    end

    it 'uses default delete_all_after_days of 730 when not specified' do
      expect do
        described_class.perform_now(delete_ingested_after_days: 180, uploads_path: uploads_path, tenant: tenant)
      end.to have_enqueued_job(CleanupSubDirectoryJob)
        .with(
          delete_ingested_after_days: 180,
          directory: carrierwave_dir,
          delete_all_after_days: 730,
          tenant: tenant
        )
    end
  end

  context 'when the Carrierwave directory does not exist' do
    before do
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(carrierwave_dir).and_return(false)
    end

    it 'does not spawn any child jobs' do
      expect do
        described_class.perform_now(delete_ingested_after_days: 180, uploads_path: uploads_path, tenant: tenant)
      end.not_to have_enqueued_job(CleanupSubDirectoryJob)
    end
  end
end
