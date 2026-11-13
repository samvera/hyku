# frozen_string_literal: true

RSpec.describe PruneStaleGuestUsersJob, type: :job do
  it 'prunes with the configured batch cap' do
    allow(PruneJobs).to receive(:max_batches).and_return(7)
    allow(StaleGuestUsersPruner).to receive(:call)

    described_class.perform_now

    expect(StaleGuestUsersPruner).to have_received(:call).with(max_batches: 7)
  end
end
