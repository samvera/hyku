# frozen_string_literal: true

RSpec.describe ValkyrieCreateDerivativesJobDecorator, type: :job do
  before { ActiveJob::Base.queue_adapter = :test }
  after  { clear_enqueued_jobs }

  let(:file_set_id)    { 'fs1' }
  let(:file_id)        { 'file1' }
  let(:video_metadata) { Hyrax::FileMetadata.new(mime_type: 'video/mp4') }
  let(:image_metadata) { Hyrax::FileMetadata.new(mime_type: 'image/png') }

  describe 'ValkyrieCreateDerivativesJob#perform' do
    context 'with an A/V file' do
      before do
        allow(Hyrax.custom_queries).to receive(:find_file_metadata_by).with(id: file_id).and_return(video_metadata)
      end

      it 'reschedules onto the :auxiliary queue' do
        expect { ValkyrieCreateDerivativesJob.perform_now(file_set_id, file_id) }
          .to have_enqueued_job(ValkyrieCreateLargeDerivativesJob).on_queue('auxiliary')
      end

      it 'does not build derivatives on the default queue' do
        expect(Hyrax::DerivativeService).not_to receive(:for)
        ValkyrieCreateDerivativesJob.perform_now(file_set_id, file_id)
      end
    end

    context 'with a non-AV file' do
      before do
        allow(Hyrax.custom_queries).to receive(:find_file_metadata_by).with(id: file_id).and_return(image_metadata)
        allow(Hyrax.storage_adapter).to receive(:find_by).and_return(double('stored_file', disk_path: '/tmp/image.png'))
        allow(Hyrax::DerivativeService).to receive(:for).and_return(instance_double(Hyrax::DerivativeService, create_derivatives: true))
        allow(Hyrax.query_service).to receive(:find_by).and_return(nil)
      end

      it 'builds derivatives inline without rescheduling' do
        expect(ValkyrieCreateLargeDerivativesJob).not_to receive(:perform_later)
        expect(Hyrax::DerivativeService).to receive(:for).with(image_metadata)
        ValkyrieCreateDerivativesJob.perform_now(file_set_id, file_id)
      end
    end
  end

  describe ValkyrieCreateLargeDerivativesJob do
    it 'runs in the :auxiliary queue' do
      expect { described_class.perform_later(file_set_id, file_id) }
        .to have_enqueued_job(described_class).on_queue('auxiliary')
    end

    it 'does not reschedule itself' do
      allow(Hyrax.config).to receive(:enable_ffmpeg).and_return(true)
      allow(Hyrax.custom_queries).to receive(:find_file_metadata_by).with(id: file_id).and_return(video_metadata)
      allow(Hyrax.storage_adapter).to receive(:find_by).and_return(double('stored_file', disk_path: '/tmp/video.mp4'))
      allow(Hyrax::DerivativeService).to receive(:for).and_return(instance_double(Hyrax::DerivativeService, create_derivatives: true))
      allow(Hyrax.query_service).to receive(:find_by).and_return(nil)

      expect(described_class).not_to receive(:perform_later)
      described_class.perform_now(file_set_id, file_id)
    end
  end
end
