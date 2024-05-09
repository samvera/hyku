# frozen_string_literal: true

FactoryBot.define do
  factory :mailboxer_message, class: 'Mailboxer::Message' do
    type { 'Mailboxer::Message' }
    body { 'Message body' }
    subject { 'Message subject' }
    association :sender, factory: :user
    association :conversation, factory: :mailboxer_conversation
  end
end
