# frozen_string_literal: true
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

  describe '#perform' do
    context 'when UserStat records exist' do
      before do
        FactoryBot.create(:user_stat) # Ensure a UserStat record exists
      end
      after do
        # Ensure we reset to the default tenant after each test
        Apartment::Tenant.switch!(Apartment.default_tenant)
      end

      it 'enqueues UserStatCollectionJob after perform' do
        switch!(account)
        allow(Hyrax.config).to receive(:analytics_reporting?).and_return(true)
        expect { UserStatCollectionJob.perform_now }.to have_enqueued_job(UserStatCollectionJob)
      end

      it 'neither imports nor reschedules when the tenant has no reports' do
        switch!(account)
        allow(Hyrax.config).to receive(:analytics_reporting?).and_return(false)
        expect(Hyrax::UserStatImporter).not_to receive(:new)
        expect { UserStatCollectionJob.perform_now }.not_to have_enqueued_job(UserStatCollectionJob)
      end
    end
  end
end
