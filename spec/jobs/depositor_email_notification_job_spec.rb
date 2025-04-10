# frozen_string_literal: true

RSpec.describe DepositorEmailNotificationJob do
  let(:account) { create(:account_with_public_schema) }
  let(:receipt) { FactoryBot.create(:mailboxer_receipt, receiver: user) }
  let!(:message) { receipt.notification }
  let!(:user) { FactoryBot.create(:user) }

  before do
    allow(Apartment::Tenant).to receive(:switch).and_yield
    ActionMailer::Base.deliveries.clear
  end

  after do
    clear_enqueued_jobs
  end

  describe '#perform' do
    it 're-enqueues the job' do
      switch!(account)
      expect { DepositorEmailNotificationJob.perform_now }.to have_enqueued_job(DepositorEmailNotificationJob)
    end

    context 'when the user has new statistics' do
      let(:statistics) { { new_file_downloads: 2, new_work_views: 3, total_file_downloads: 6, total_file_views: 7, total_work_views: 16 } }

      before do
        allow(User).to receive(:all).and_return([user])
        allow(user).to receive(:statistics_for).and_return(statistics)
      end

      it 'sends email to users' do
        switch!(account)
        expect { described_class.perform_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context 'when the user has zero new counts in statistics' do
      let(:statistics) { { new_file_downloads: 0, new_work_views: 0, total_file_downloads: 6, total_file_views: 7, total_work_views: 16 } }

      before do
        allow(User).to receive(:all).and_return([user])
        allow(user).to receive(:statistics_for).and_return(statistics)
      end

      it 'does not send emails to users' do
        switch!(account)
        described_class.perform_now
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    context 'when the user has no new statistics' do
      let(:statistics) { nil }

      it 'sends does not send email to user' do
        switch!(account)
        expect { DepositorEmailNotificationJob.perform_now }.to_not change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end
