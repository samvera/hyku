# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # limit to 5 attempts
  retry_on StandardError, wait: :exponentially_longer, attempts: 5 do |_job, _exception|
    # Log error, do nothing, etc.
  end
end
