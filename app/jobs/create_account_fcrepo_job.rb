# This job is the same as its parent, but chains to the next step
class CreateAccountFcrepoJob < CreateFcrepoEndpointJob
  after_perform do |job|
    CreateDefaultAdminSetJob.perform_later(job.arguments.first)
  end
end
