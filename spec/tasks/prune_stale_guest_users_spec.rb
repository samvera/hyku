# frozen_string_literal: true

require 'rake'

RSpec.describe 'hyku:prune_stale_guest_users' do
  let!(:stale_guest) { FactoryBot.create(:guest_user, stale: true) }
  let!(:fresh_guest) { FactoryBot.create(:guest_user) }
  let!(:stale_member) { FactoryBot.create(:user).tap { |user| user.update!(updated_at: 8.days.ago) } }

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('BATCH_SLEEP_SECONDS', anything).and_return('0')
  end

  def stub_env(env)
    env.each { |name, value| allow(ENV).to receive(:fetch).with(name, anything).and_return(value) }
  end

  it 'deletes only stale guest users' do
    run_task('hyku:prune_stale_guest_users')

    expect(User.unscoped.where(id: [stale_guest.id, fresh_guest.id, stale_member.id]))
      .to contain_exactly(fresh_guest, stale_member)
  end

  it 'deletes in batches' do
    FactoryBot.create(:guest_user, stale: true)
    stub_env('BATCH_SIZE' => '1')

    run_task('hyku:prune_stale_guest_users')

    expect(User.unscoped.where(guest: true).where('updated_at < ?', 7.days.ago)).to be_empty
  end

  it 'honors OLDER_THAN_DAYS' do
    stub_env('OLDER_THAN_DAYS' => '0')

    run_task('hyku:prune_stale_guest_users')

    expect(User.unscoped.where(guest: true)).to be_empty
    expect(User.unscoped.find(stale_member.id)).to eq stale_member
  end

  it 'deletes nothing on a dry run' do
    stub_env('DRY_RUN' => 'true')

    run_task('hyku:prune_stale_guest_users')

    expect(User.unscoped.where(guest: true).count).to eq 2
  end
end
