# frozen_string_literal: true

class BatchEmailNotificationJob < ApplicationJob
  def perform
    # Query for all users that have email_frequency turned off
    users = User.where.not(batch_email_frequency: "never")
    users.each do |user|
      next unless send_email_today?(user)
      # Find all unread and undelivered messages within the frequency range of a user
      undelivered_messages =
        Mailboxer::Message.joins(:receipts)
                          .where(mailboxer_receipts: {
                                   receiver_id: user.id,
                                   receiver_type: 'User',
                                   is_delivered: false,
                                   is_read: false
                                 })
                          .where('mailboxer_notifications.created_at >= ?', frequency_date(user.batch_email_frequency))
                          .select('mailboxer_notifications.*')
                          .distinct
                          .to_a

      next if undelivered_messages.blank?
      send_email(user, undelivered_messages, current_account)

      # Mark the messages as delivered and read
      undelivered_messages.each do |message|
        message.receipts.each do |receipt|
          receipt.update(is_delivered: true, is_read: true)
        end
      end

      user.last_emailed_at = Time.current
    end
    BatchEmailNotificationJob.set(wait_until: Date.tomorrow.midnight).perform_later
  end

  private

  def send_email_today?(user)
    return true if user.last_emailed_at.nil?

    next_email_date = case user.batch_email_frequency
                      when "daily"
                        user.last_emailed_at + 1.day
                      when "weekly"
                        user.last_emailed_at + 1.week
                      when "monthly"
                        user.last_emailed_at + 1.month
                      end

    Time.current >= next_email_date
  end

  def frequency_date(frequency)
    case frequency
    when "daily"
      1.day.ago
    when "weekly"
      1.week.ago
    when "monthly"
      1.month.ago
    end
  end

  def send_email(user, undelivered_messages, account)
    HykuMailer.summary_email(user, undelivered_messages, account).deliver_now
  end
end
