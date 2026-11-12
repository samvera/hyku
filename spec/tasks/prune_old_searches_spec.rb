# frozen_string_literal: true

require 'rake'

RSpec.describe 'hyku:prune_old_searches' do
  let(:account) { double(Account, tenant: Apartment::Tenant.current, cname: 'example.test') }
  let!(:old_anonymous) { Search.create!(query_params: { q: 'old' }, created_at: 40.days.ago) }
  let!(:recent_anonymous) { Search.create!(query_params: { q: 'recent' }, created_at: 1.day.ago) }
  let!(:old_saved) { Search.create!(query_params: { q: 'saved' }, user_id: 1, created_at: 40.days.ago) }

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before do
    allow(Account).to receive(:find_each).and_yield(account)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('BATCH_SLEEP_SECONDS', anything).and_return('0')
  end

  def stub_env(env)
    env.each { |name, value| allow(ENV).to receive(:fetch).with(name, anything).and_return(value) }
  end

  it 'deletes only old searches that no user saved' do
    run_task('hyku:prune_old_searches')

    expect(Search.all).to contain_exactly(recent_anonymous, old_saved)
  end

  it 'deletes in batches' do
    Search.create!(query_params: { q: 'old2' }, created_at: 41.days.ago)
    stub_env('BATCH_SIZE' => '1')

    run_task('hyku:prune_old_searches')

    expect(Search.all).to contain_exactly(recent_anonymous, old_saved)
  end

  it 'honors OLDER_THAN_DAYS' do
    stub_env('OLDER_THAN_DAYS' => '0')

    run_task('hyku:prune_old_searches')

    expect(Search.all).to contain_exactly(old_saved)
  end

  it 'deletes nothing on a dry run' do
    stub_env('DRY_RUN' => 'true')

    run_task('hyku:prune_old_searches')

    expect(Search.count).to eq 3
  end

  it 'prunes each tenant inside its own Apartment schema' do
    allow(Apartment::Tenant).to receive(:switch).and_call_original

    run_task('hyku:prune_old_searches')

    expect(Apartment::Tenant).to have_received(:switch).with(account.tenant)
  end

  it 'keeps going after a tenant fails, then exits non-zero naming it' do
    other = double(Account, tenant: Apartment::Tenant.current, cname: 'other.test')
    allow(Account).to receive(:find_each).and_yield(account).and_yield(other)
    calls = 0
    allow(Search).to receive(:where).and_wrap_original do |original, *args|
      calls += 1
      raise ActiveRecord::StatementInvalid, 'boom' if calls == 1

      original.call(*args)
    end

    expect(run_task('hyku:prune_old_searches')).to include 'failed for: example.test'
    expect(Search.all).to contain_exactly(recent_anonymous, old_saved)
  end
end
