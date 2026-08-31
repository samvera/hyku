# frozen_string_literal: true

# Real ActiveJob subclasses (not test doubles) used to exercise the actual
# perform_now -> run_callbacks(:perform) -> around_perform path, so these
# specs prove the real behavior rather than a mocked approximation of it.
class RequestStoreWritingJob < ApplicationJob
  def perform
    RequestStore.store[:probe] = 'set during job'
  end
end

class RequestStoreWritingThenRaisingJob < ApplicationJob
  def perform
    RequestStore.store[:probe] = 'set before raising'
    raise StandardError, 'boom'
  end
end

RSpec.describe ActiveJobRequestStoreReset do
  around do |example|
    RequestStore.clear!
    example.run
    RequestStore.clear!
  end

  it 'clears RequestStore after a job performs successfully' do
    RequestStoreWritingJob.perform_now

    expect(RequestStore.store).to be_empty
  end

  it 'clears RequestStore even when the job raises (ApplicationJob#retry_on rescues and re-enqueues it)' do
    expect { RequestStoreWritingThenRaisingJob.perform_now }.not_to raise_error

    expect(RequestStore.store).to be_empty
  end

  it 'does not leak state from one job execution into the next job on the same thread' do
    RequestStoreWritingJob.perform_now

    probe_reading_job = Class.new(ApplicationJob) do
      def perform
        RequestStore.store[:probe]
      end
    end

    expect(probe_reading_job.perform_now).to be_nil
  end
end
