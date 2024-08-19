# frozen_string_literal: true

RSpec.describe BatchEmailNotificationJob do
  let(:account) { create(:account_with_public_schema) }
  let(:receipt) { FactoryBot.create(:mailboxer_receipt, receiver: user) }
  let!(:message) { receipt.notification }
  let!(:user) { FactoryBot.create(:user, batch_email_frequency: frequency) }

  before do
    allow(Apartment::Tenant).to receive(:switch).and_yield
    ActionMailer::Base.deliveries.clear
    switch!(account)
  end

  after do
    clear_enqueued_jobs
  end

  describe '#perform' do
    let(:frequency) { 'daily' }

    it 'marks the message as delivered' do
      expect { BatchEmailNotificationJob.perform_now }.to change { message.receipts.first.is_delivered }.from(false).to(true)
    end

    it 're-enqueues the job' do
      expect { BatchEmailNotificationJob.perform_now }.to have_enqueued_job(BatchEmailNotificationJob)
    end

    context 'when the user has a daily frequency' do
      let(:frequency) { 'daily' }

      it 'sends email to users with batch_email_frequency set' do
        expect { BatchEmailNotificationJob.perform_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context 'when the user has a weekly frequency' do
      let(:frequency) { 'weekly' }
      let(:user) { FactoryBot.create(:user, batch_email_frequency: frequency, last_emailed_at:) }

      context 'when the user was last emailed less than a week ago' do
        let(:last_emailed_at) { 5.days.ago }

        it 'does not send an email to users with batch_email_frequency set' do
          expect { BatchEmailNotificationJob.perform_now }.to_not change { ActionMailer::Base.deliveries.count }
        end
      end

      context 'when the user was last emailed more than a week ago' do
        let(:last_emailed_at) { 8.days.ago }

        it 'sends email to users with batch_email_frequency set' do
          expect { BatchEmailNotificationJob.perform_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end
    end

    context 'when the user has a monthly frequency' do
      let(:frequency) { 'monthly' }
      let(:user) { FactoryBot.create(:user, batch_email_frequency: frequency, last_emailed_at:) }

      context 'when the user was last emailed less than a month ago' do
        let(:last_emailed_at) { 20.days.ago }

        it 'does not send an email to users with batch_email_frequency set' do
          expect { BatchEmailNotificationJob.perform_now(account) }.to_not change { ActionMailer::Base.deliveries.count }
        end
      end

      context 'when the user was last emailed more than a month ago' do
        let(:last_emailed_at) { 40.days.ago }

        it 'sends email to users with batch_email_frequency set' do
          expect { BatchEmailNotificationJob.perform_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end
    end
  end
end
