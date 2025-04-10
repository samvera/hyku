# frozen_string_literal: true

class DepositorEmailNotificationJob < ApplicationJob
  def perform
    users = User.all

    users.each do |user|
      statistics = user.statistics_for
      next if statistics.nil?

      next if statistics[:new_work_views].zero? && statistics[:new_file_downloads].zero?

      HykuMailer.depositor_email(user, statistics, current_account).deliver_now
    end
    DepositorEmailNotificationJob.set(wait_until: (Time.zone.now + 1.month).beginning_of_month).perform_later
  end
end
