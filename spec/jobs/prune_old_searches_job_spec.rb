# frozen_string_literal: true

RSpec.describe PruneOldSearchesJob, type: :job do
  before do
    allow(PruneJobs).to receive(:max_batches).and_return(7)
    allow(OldSearchesPruner).to receive(:call)
  end

  it 'prunes with the configured batch cap' do
    described_class.perform_now

    expect(OldSearchesPruner).to have_received(:call).with(max_batches: 7)
  end

  it 'enqueues itself for the next night' do
    expect { described_class.perform_now }.to have_enqueued_job(described_class)
  end
end
