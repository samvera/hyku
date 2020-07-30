# frozen_string_literal: true

require 'active_job/queue_adapters/better_active_elastic_job_adapter'

RSpec.describe ActiveJob::QueueAdapters::BetterActiveElasticJobAdapter do
  let(:queue_url) { 'http://example.com/queue/url' }
  let(:account) { create(:account) }
  let(:aws_sqs_client) { instance_double(Aws::SQS::Client) }
  let(:job) { CreateSolrCollectionJob.new(account) }

  before do
    allow(Settings.active_job_queue).to receive(:url).and_return(queue_url)
    Rails.application.config.active_elastic_job.secret_key_base = Rails.application.secrets[:secret_key_base]
    allow(described_class).to receive(:aws_sqs_client).and_return(aws_sqs_client)
  end

  describe '#enqueue' do
    it 'uses the configured queue' do
      expect(aws_sqs_client).to receive(:send_message) do |msg|
        expect(msg[:queue_url]).to eq queue_url
      end

      subject.enqueue job
    end
  end
end
