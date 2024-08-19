# frozen_string_literal: true

class DeleteOldGuestsJob < ApplicationJob
  non_tenant_job
  after_perform do |_job|
    reenqueue
  end

  def perform
    User.unscope(:where).where("guest = ? and updated_at < ?", true, 7.days.ago).destroy_all
  end

  private

  def reenqueue
    DeleteOldGuestsJob.set(wait_until: Date.tomorrow.midnight).perform_later
  end
end
