# frozen_string_literal: true

RSpec.describe StaleGuestUsersPruner do
  let!(:stale_guest) { FactoryBot.create(:guest_user, stale: true) }
  let!(:fresh_guest) { FactoryBot.create(:guest_user) }
  let!(:stale_member) { FactoryBot.create(:user).tap { |user| user.update!(updated_at: 8.days.ago) } }

  def stale_count
    User.unscoped.where(guest: true).where('updated_at < ?', 7.days.ago).count
  end

  def create_stale
    FactoryBot.create(:guest_user, stale: true)
  end

  it_behaves_like 'a batched pruner'

  it 'deletes only stale guest users and returns the count' do
    expect(described_class.call(batch_sleep_seconds: 0)).to eq 1
    expect(User.unscoped.where(id: [stale_guest.id, fresh_guest.id, stale_member.id]))
      .to contain_exactly(fresh_guest, stale_member)
  end

  it 'honors older_than_days' do
    described_class.call(older_than_days: 0, batch_sleep_seconds: 0)

    expect(User.unscoped.where(guest: true)).to be_empty
    expect(User.unscoped.find(stale_member.id)).to eq stale_member
  end
end
