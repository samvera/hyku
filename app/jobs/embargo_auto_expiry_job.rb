# frozen_string_literal: true

class EmbargoAutoExpiryJob < ApplicationJob
  def perform
    # From Hyrax app/jobs/embargo_expiry_job
    EmbargoExpiryJob.perform_later
  end
end
