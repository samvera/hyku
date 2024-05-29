# frozen_literal: true

class DepositorEmailNotificationJob < ApplicationJob
  non_tenant_job

  after_perform do |job|
    reenqueue(job.arguments.first)
  end

  def perform(account)
    Apartment::Tenant.switch(account.tenant) do
      stats_period = (Date.today - 1.month).beginning_of_month..(Date.today - 1.month).end_of_month
      users = User.all

      users.each do |user|
        statistics = gather_statistics_for(user, stats_period)
        next if statistics.nil?

        HykuMailer.depositor_email(user, statistics, account).deliver_now
      end
    end
  end

  private

  def reenqueue(account)
    DepositorEmailNotificationJob.set(wait_until: Date.next_month.beginning_of_month).perform_later(account)
  end

  def gather_statistics_for(user, stats_period)
    # Dummy statistics - replace with actual logic to calculate view and download counts. 
    # users.stats could be useful: https://github.com/samvera/hyrax/blob/4d2c654a8b9f144b35a6e013b31f80cb4cf47aeb/app/models/concerns/hyrax/user_usage_stats.rb#L3
    # there's also this: https://github.com/samvera/hyrax/blob/main/app/presenters/hyrax/file_usage.rb 
    # Fetching statistics for the previous month
    last_month_stats = user.stats.where(date: stats_period)

    return nil if last_month_stats.empty?

    {
      new_file_downloads: last_month_stats.sum(:file_downloads),
      new_work_views: last_month_stats.sum(:work_views),
      total_file_views: user.total_file_views,
      total_file_downloads: user.total_file_downloads, 
      total_work_views: user.total_work_views
    }
  end
end
