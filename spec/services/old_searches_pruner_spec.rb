# frozen_string_literal: true

RSpec.describe OldSearchesPruner do
  let!(:old_anonymous) { Search.create!(query_params: { q: 'old' }, created_at: 40.days.ago) }
  let!(:recent_anonymous) { Search.create!(query_params: { q: 'recent' }, created_at: 1.day.ago) }
  let!(:old_saved) { Search.create!(query_params: { q: 'saved' }, user_id: 1, created_at: 40.days.ago) }

  def stale_count
    Search.where(user_id: nil).where('created_at < ?', 30.days.ago).count
  end

  def create_stale
    Search.create!(query_params: { q: SecureRandom.hex(3) }, created_at: 41.days.ago)
  end

  it_behaves_like 'a batched pruner'

  it 'deletes only old searches that no user saved and returns the count' do
    expect(described_class.call(batch_sleep_seconds: 0)).to eq 1
    expect(Search.all).to contain_exactly(recent_anonymous, old_saved)
  end

  it 'honors older_than_days' do
    described_class.call(older_than_days: 0, batch_sleep_seconds: 0)

    expect(Search.all).to contain_exactly(old_saved)
  end
end
