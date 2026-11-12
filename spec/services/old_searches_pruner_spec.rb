# frozen_string_literal: true

RSpec.describe OldSearchesPruner do
  let!(:old_anonymous) { Search.create!(query_params: { q: 'old' }, created_at: 40.days.ago) }
  let!(:recent_anonymous) { Search.create!(query_params: { q: 'recent' }, created_at: 1.day.ago) }
  let!(:old_saved) { Search.create!(query_params: { q: 'saved' }, user_id: 1, created_at: 40.days.ago) }

  it 'deletes only old searches that no user saved and returns the count' do
    expect(described_class.call(batch_sleep_seconds: 0)).to eq 1
    expect(Search.all).to contain_exactly(recent_anonymous, old_saved)
  end

  it 'honors older_than_days' do
    described_class.call(older_than_days: 0, batch_sleep_seconds: 0)

    expect(Search.all).to contain_exactly(old_saved)
  end

  it 'deletes nothing on a dry run but reports the count' do
    expect(described_class.call(dry_run: true)).to eq 1
    expect(Search.count).to eq 3
  end

  it 'stops after max_batches' do
    2.times { |i| Search.create!(query_params: { q: "old#{i}" }, created_at: 41.days.ago) }

    expect(described_class.call(batch_size: 1, max_batches: 2, batch_sleep_seconds: 0)).to eq 2
    expect(Search.where(user_id: nil).where('created_at < ?', 30.days.ago).count).to eq 1
  end
end
