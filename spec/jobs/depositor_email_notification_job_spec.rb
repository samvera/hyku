# frozen_string_literal: true

RSpec.describe DepositorEmailNotificationJob do
  let(:account) { FactoryBot.create(:account) }
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
      expect { DepositorEmailNotificationJob.perform_now(account) }.to have_enqueued_job(DepositorEmailNotificationJob).with(account)
    end

    context 'when the user has new statistics' do
      let(:statistics) { { new_file_downloads: 2, new_work_views: 3, total_file_downloads: 6, total_file_views: 7, total_work_views: 16 } }

      before do
        allow(User).to receive(:all).and_return([user])
        allow(user).to receive(:statistics_for).and_return(statistics)
      end

      it 'sends email to users' do
        expect { described_class.perform_now(account) }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context 'when the user has no new statistics' do
      let(:statistics) { nil }

      it 'sends does not send email to user' do
        expect { DepositorEmailNotificationJob.perform_now(account) }.to_not change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end
