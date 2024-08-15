require 'rails_helper'

RSpec.describe UserStatCollectionJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter = :test
    FactoryBot.create(:group, name: "public")
  end

  after do
    clear_enqueued_jobs
  end

  let(:account) { create(:account_with_public_schema) }

  describe '#reenqueue' do
    it 'Enques an TenantMaintenanceJob after perform' do
      switch!(account)
      expect { UserStatCollectionJob.perform_now }.to have_enqueued_job(UserStatCollectionJob)
    end
  end
end
