# frozen_string_literal: true

FactoryBot.define do
  factory :mailboxer_conversation, class: 'Mailboxer::Conversation' do
    subject { 'Conversation subject' }
  end
end
