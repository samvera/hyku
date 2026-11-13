# frozen_string_literal: true

# Including contexts define #stale_count (rows the pruner would delete) and #create_stale (adds one such row).
RSpec.shared_examples 'a batched pruner' do
  it 'deletes nothing on a dry run but reports the count' do
    before_count = stale_count

    expect(described_class.call(dry_run: true)).to eq before_count
    expect(stale_count).to eq before_count
  end

  it 'stops after max_batches' do
    2.times { create_stale }
    before_count = stale_count

    expect(described_class.call(batch_size: 1, max_batches: 2, batch_sleep_seconds: 0)).to eq 2
    expect(stale_count).to eq before_count - 2
  end
end
