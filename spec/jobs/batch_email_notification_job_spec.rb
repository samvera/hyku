# frozen_string_literal: true

RSpec.describe BatchEmailNotificationJob do
  let(:subject) { BatchEmailNotificationJob.perform_now }
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
    before do
      UserBatchEmail.find_or_create_by(user: user).update(last_emailed_at: last_emailed)
    end

    context 'basic job behavior' do
      let(:frequency) { 'daily' }
      let(:last_emailed) { nil }

      it 'marks the message as delivered and read' do
        expect { subject }.to change { message.receipts.first.is_delivered }.from(false).to(true)
        expect(message.receipts.first.is_read).to be true
      end

      it 're-enqueues the job' do
        expect { subject }.to have_enqueued_job(BatchEmailNotificationJob)
      end
    end

    context 'when the user has a daily frequency' do
      let(:frequency) { 'daily' }
      let(:last_emailed) { 1.day.ago }

      it 'sends email to users with batch_email_frequency set' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context 'when the user has a weekly frequency' do
      let(:frequency) { 'weekly' }
      let(:user) { FactoryBot.create(:user, batch_email_frequency: frequency) }

      context 'when the user was last emailed less than a week ago' do
        let(:last_emailed) { 5.days.ago }

        it 'does not send an email to users with batch_email_frequency set' do
          expect { subject }.to_not change { ActionMailer::Base.deliveries.count }
        end
      end

      context 'when the user was last emailed more than a week ago' do
        let(:last_emailed) { 8.days.ago }

        it 'sends email to users with batch_email_frequency set' do
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end
    end

    context 'when the user has a monthly frequency' do
      let(:frequency) { 'monthly' }
      let(:user) { FactoryBot.create(:user, batch_email_frequency: frequency) }

      context 'when the user was last emailed less than a month ago' do
        let(:last_emailed) { 20.days.ago }

        it 'does not send an email to users with batch_email_frequency set' do
          expect { subject }.to_not change { ActionMailer::Base.deliveries.count }
        end
      end

      context 'when the user was last emailed more than a month ago' do
        let(:last_emailed) { 40.days.ago }

        it 'sends email to users with batch_email_frequency set' do
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end
    end

    context 'when the user has a never frequency' do
      let(:frequency) { 'never' }
      let(:last_emailed) { nil }

      it 'does not send any emails' do
        expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it 'marks messages as delivered' do
        subject
        expect(receipt.reload.is_delivered).to be true
      end
    end

    context 'notification inclusion tests' do
      let(:frequency) { 'daily' }
      let(:last_emailed) { nil }

      context 'with multiple unread notifications' do
        let!(:receipt2) { FactoryBot.create(:mailboxer_receipt, receiver: user) }
        let!(:receipt3) { FactoryBot.create(:mailboxer_receipt, receiver: user) }
        let!(:message2) { receipt2.notification }
        let!(:message3) { receipt3.notification }

        it 'includes all unread notifications in the email' do
          expect(HykuMailer).to receive(:summary_email).with(user, containing_exactly(message, message2, message3), account).and_call_original
          subject
        end

        it 'marks all notifications as delivered and read' do
          subject
          expect(receipt.reload.is_delivered).to be true
          expect(receipt2.reload.is_delivered).to be true
          expect(receipt3.reload.is_delivered).to be true
          expect(receipt.reload.is_read).to be true
          expect(receipt2.reload.is_read).to be true
          expect(receipt3.reload.is_read).to be true
        end

        context 'with a mix of read and unread notifications' do
          before do
            receipt2.update(is_read: true) # Read
            receipt3.update(is_read: false) # Unread
          end

          it 'only includes unread notifications in the email' do
            expect(HykuMailer).to receive(:summary_email).with(user, containing_exactly(message, message3), account).and_call_original
            subject
          end

          it 'marks all notifications as delivered and read' do
            subject
            expect(receipt.reload.is_delivered).to be true
            expect(receipt3.reload.is_delivered).to be true
            expect(receipt.reload.is_read).to be true
            expect(receipt3.reload.is_read).to be true
          end

          it 'includes correct notifications in email body' do
            subject
            email_body = ActionMailer::Base.deliveries.last.body.encoded
            expect(email_body).to include(message.body) # Should include unread message
            expect(email_body).not_to include(message2.body)   # Should not include read message
            expect(email_body).to include(message3.body)       # Should include unread message
          end
        end
      end

      context 'when user has no unread notifications' do
        let(:frequency) { 'daily' }
        let(:last_emailed) { nil }

        before do
          receipt.update(is_read: true)
        end

        it 'does not send an email' do
          expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end
  end
end
