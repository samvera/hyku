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

  describe 'uploads cleanup' do
    it 'does not enqueue UploadsCleanupJob by default' do
      switch!(account)
      expect { TenantMaintenanceJob.perform_now }.not_to have_enqueued_job(UploadsCleanupJob)
    end

    it 'enqueues UploadsCleanupJob when scheduled uploads cleanup is enabled' do
      allow(UploadsCleanupJob).to receive(:enabled?).and_return(true)
      switch!(account)
      expect { TenantMaintenanceJob.perform_now }.to have_enqueued_job(UploadsCleanupJob)
    end
  end
end
