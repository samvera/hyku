class LeaseAutoExpiryJob <  ApplicationJob

  def perform
    # From Hyrax app/jobs/lease_expiry_job
    LeaseExpiryJob.perform_later
  end

end
