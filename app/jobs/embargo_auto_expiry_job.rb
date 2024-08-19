# frozen_string_literal: true

# One of these must run per tenant
class EmbargoAutoExpiryJob < ApplicationJob
  def perform
    EmbargoExpiryJob.perform_now
    EmbargoAutoExpiryJob.set(wait_until: Date.tomorrow.midnight).perform_later
  end
end
