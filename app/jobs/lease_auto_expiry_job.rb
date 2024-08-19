# frozen_string_literal: true

# One of these must run per tenant
class LeaseAutoExpiryJob < ApplicationJob
  def perform
    LeaseExpiryJob.perform_now
    LeaseAutoExpiryJob.set(wait_until: Date.tomorrow.midnight).perform_later
  end
end
