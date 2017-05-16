require 'active_elastic_job'

module ActiveJob
  module QueueAdapters
    class BetterActiveElasticJobAdapter < ActiveElasticJobAdapter
      class << self
        # We're replacing this method so that we invoke the SQS::Client with no parameters, effectively
        # using the default credentials set by ElasticBeanstalk.
        # Upstream method: https://github.com/tawan/active-elastic-job/blob/8a870e6ca4542438d2ed167ed2cb9b1473ee702d/lib/active_job/queue_adapters/active_elastic_job_adapter.rb#L168
        def aws_sqs_client
          @aws_sqs_client ||= Aws::SQS::Client.new
        end

        private

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
