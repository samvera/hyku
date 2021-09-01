# frozen_string_literal: true

class EmbargoAutoExpiryJob < ApplicationJob
  non_tenant_job
  after_perform do |job|
    reenqueue(job.arguments.first)
  end

  def perform(account)
    Apartment::Tenant.switch(account.tenant) do
      # From Hyrax app/jobs/embargo_expiry_job
      EmbargoExpiryJob.perform_now
    end
  end

  private

    def reenqueue(account)
      EmbargoAutoExpiryJob.set(wait_until: Date.tomorrow.midnight).perform_later(account)
    end
end
