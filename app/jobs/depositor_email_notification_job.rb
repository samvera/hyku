# frozen_literal: true

class DepositorEmailNotificationJob < ApplicationJob
  non_tenant_job

  after_perform do |job|
    reenqueue(job.arguments.first)
  end

  def perform(account)
    Apartment::Tenant.switch(account.tenant) do
      users = User.all

      users.each do |user|
        statistics = user.statistics_for
        next if statistics.nil?

        HykuMailer.depositor_email(user, statistics, account).deliver_now
      end
    end
  end

  # private

  def reenqueue(account)
    DepositorEmailNotificationJob.set(wait_until: Date.next_month.beginning_of_month).perform_later(account)
  end
end
