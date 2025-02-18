# frozen_string_literal: true

FactoryBot.define do
  sequence :message_body do |n|
    "Message body #{n}"
  end

  factory :mailboxer_message, class: 'Mailboxer::Message' do
    type { 'Mailboxer::Message' }
    body { generate(:message_body) }
    subject { 'Message subject' }
    association :sender, factory: :user
    association :conversation, factory: :mailboxer_conversation
  end
end
