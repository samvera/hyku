# frozen_string_literal: true

FactoryBot.define do
  factory :mailboxer_notification, class: 'Mailboxer::Notification' do
    type { 'Mailboxer::Notification' }
    body { 'Notification body' }
    subject { 'Notification subject' }
    association :sender, factory: :user
  end
end
