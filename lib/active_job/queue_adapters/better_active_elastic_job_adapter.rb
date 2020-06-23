require 'aws-sdk-sqs'
require 'active_elastic_job'

module ActiveJob
  module QueueAdapters
    class BetterActiveElasticJobAdapter < ActiveElasticJobAdapter
      class << self
        private

          # Upstream dynamically calculated queue urls for each job; we'd rather
          # route jobs into a pre-determined queue url instead.
          def queue_url(*_)
            if Settings.active_job_queue.url
              Settings.active_job_queue.url
            else
              super
            end
          end
      end
    end
  end
end
