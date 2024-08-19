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
end
