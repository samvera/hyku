# frozen_string_literal: true
require 'active_job'
require 'active_job_tenant'
require 'active_job_request_store_reset'

class ActiveJob::Base
  include ActiveJobTenant
  include ActiveJobRequestStoreReset
end
