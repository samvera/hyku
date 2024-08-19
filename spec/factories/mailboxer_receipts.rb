# frozen_string_literal: true

FactoryBot.define do
  factory :mailboxer_receipt, class: 'Mailboxer::Receipt' do
    association :receiver, factory: :user
    association :notification, factory: :mailboxer_message
    is_read { false }
    trashed { false }
    deleted { false }
    mailbox_type { "inbox" }
    is_delivered { false }
  end
end
