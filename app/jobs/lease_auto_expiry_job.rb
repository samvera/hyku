# frozen_string_literal: true

class LeaseAutoExpiryJob < ApplicationJob
  non_tenant_job
  after_perform do |job|
    reenqueue(job.arguments.first)
  end

  def perform(account)
    Apartment::Tenant.switch(account.tenant) do
      # From Hyrax app/jobs/lease_expiry_job
      LeaseExpiryJob.perform_now
    end
  end

  private

    def reenqueue(account)
      LeaseAutoExpiryJob.set(wait_until: Date.tomorrow.midnight).perform_later(account)
    end
end
