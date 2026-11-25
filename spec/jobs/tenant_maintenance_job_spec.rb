# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TenantMaintenanceJob, type: :job do
  let(:account) { create(:account_with_public_schema) }

  describe '#reenqueue' do
    it 'Enques an TenantMaintenanceJob after perform' do
      switch!(account)
      expect { TenantMaintenanceJob.perform_now }.to have_enqueued_job(TenantMaintenanceJob)
    end
  end

  describe 'guest user pruning' do
    it 'enqueues PruneStaleGuestUsersJob' do
      switch!(account)
      expect { TenantMaintenanceJob.perform_now }.to have_enqueued_job(PruneStaleGuestUsersJob)
    end
  end
  describe 'uploads cleanup' do
    # Stub the flag itself: in CI the ENV.fetch stub sometimes did not take effect and the example
    # failed with "enqueued 0". Reading HYKU_SCHEDULE_UPLOADS_CLEANUP is covered in uploads_cleanup_job_spec.
    it 'does not enqueue UploadsCleanupJob when scheduled uploads cleanup is disabled' do
      switch!(account)
      allow(UploadsCleanupJob).to receive(:enabled?).and_return(false)
      expect { TenantMaintenanceJob.perform_now }.not_to have_enqueued_job(UploadsCleanupJob)
    end

    it 'enqueues UploadsCleanupJob when scheduled uploads cleanup is enabled' do
      switch!(account)
      allow(UploadsCleanupJob).to receive(:enabled?).and_return(true)
      expect { TenantMaintenanceJob.perform_now }.to have_enqueued_job(UploadsCleanupJob)
    end
  end
end
