# frozen_string_literal: true

# OVERRIDE: Mailboxer v0.15.1 to mark receipts as delivered for users that
#           set their `batch_email_frequency` to 'never'

module Mailboxer
  module ReceiptDecorator
    extend ActiveSupport::Concern

    prepended do
      after_create :mark_as_delivered
    end

    def mark_as_delivered
      user = User.find_by(id: receiver_id)
      return unless user&.batch_email_frequency == 'never'

      update(is_delivered: true)
    end
  end
end

Mailboxer::Receipt.prepend(Mailboxer::ReceiptDecorator)
