# frozen_string_literal: true

RSpec.describe Mailboxer::Receipt, type: :decorator do
  describe '#mark_as_delivered' do
    context 'when the user has batch_email_frequency set to never' do
      let(:user) { create(:user, batch_email_frequency: 'never') }
      let(:receipt) { create(:mailboxer_receipt, receiver: user) }

      before do
        # ensure we have a undelivered receipt
        receipt.update(is_delivered: false)
      end

      it 'marks the receipt as delivered' do
        expect { receipt.mark_as_delivered }.to change { receipt.is_delivered }.from(false).to(true)
      end
    end

    context 'when the user does not have batch_email_frequency set to never' do
      let(:user) { create(:user, batch_email_frequency: 'daily') }
      let(:receipt) { create(:mailboxer_receipt, receiver: user) }

      before do
        # ensure we have a undelivered receipt
        receipt.update(is_delivered: false)
      end

      it 'does not mark the receipt as delivered' do
        expect { receipt.mark_as_delivered }.not_to change { receipt.is_delivered }
      end
    end
  end
end
