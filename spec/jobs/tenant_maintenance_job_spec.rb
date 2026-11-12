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
    it 'does not enqueue PruneStaleGuestUsersJob by default' do
      switch!(account)
      expect { TenantMaintenanceJob.perform_now }.not_to have_enqueued_job(PruneStaleGuestUsersJob)
    end

    it 'enqueues PruneStaleGuestUsersJob when prune jobs are enabled' do
      allow(PruneJobs).to receive(:enabled?).and_return(true)
      switch!(account)
      expect { TenantMaintenanceJob.perform_now }.to have_enqueued_job(PruneStaleGuestUsersJob)
    end
  end
end
