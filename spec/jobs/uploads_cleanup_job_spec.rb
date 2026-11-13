# frozen_string_literal: true

RSpec.describe UploadsCleanupJob, type: :job do
  describe '.enabled?' do
    before { allow(ENV).to receive(:fetch).and_call_original }

    it 'is off by default' do
      expect(described_class).not_to be_enabled
    end

    it 'is on when HYKU_SCHEDULE_UPLOADS_CLEANUP is true' do
      allow(ENV).to receive(:fetch).with('HYKU_SCHEDULE_UPLOADS_CLEANUP', anything).and_return('true')

      expect(described_class).to be_enabled
    end
  end

  describe '#perform' do
    it 'runs the cleanup service with the options from the environment' do
      service = instance_double(UploadsCleanupService, run: nil)
      allow(UploadsCleanupService).to receive(:options_from_env).and_return(dry_run: true)
      allow(UploadsCleanupService).to receive(:new).with(dry_run: true).and_return(service)

      described_class.perform_now

      expect(service).to have_received(:run)
    end
  end
end
