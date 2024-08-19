# frozen_string_literal: true
require 'active_job'
require 'active_job_tenant'

class ActiveJob::Base
  include ActiveJobTenant
end
