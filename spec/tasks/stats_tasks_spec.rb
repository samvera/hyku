# frozen_string_literal: true

require 'rake'

RSpec.describe 'hyku:purge_cached_stats' do
  let(:account) { double(Account, tenant: Apartment::Tenant.current, cname: 'example.test') }
  let(:since) { '2026-10-01' }

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before do
    allow(Account).to receive(:find_each).and_yield(account)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('SINCE').and_return(since)

    [Date.new(2026, 9, 30), Date.new(2026, 10, 1)].each do |date|
      created_at = updated_at = Date.new(2026, 9, 30)
      FileViewStat.create!(date:, created_at:, updated_at:, views: 1, file_id: 'f1', user_id: 1)
      FileDownloadStat.create!(date:, created_at:, updated_at:, downloads: 1, file_id: 'f1', user_id: 1)
      WorkViewStat.create!(date:, created_at:, updated_at:, work_views: 1, work_id: 'w1', user_id: 1)
      UserStat.create!(date:, created_at:, updated_at:, file_views: 1, file_downloads: 1, work_views: 1, user_id: 1)
    end
  end

  it 'deletes stats dated on or after SINCE and keeps earlier ones' do
    run_task('hyku:purge_cached_stats')

    [FileViewStat, FileDownloadStat, WorkViewStat, UserStat].each do |klass|
      expect(klass.pluck(:date).map(&:to_date)).to eq [Date.new(2026, 9, 30)]
    end
  end

  it 'deletes earlier-dated stats cached on or after SINCE' do
    stat = FileViewStat.create!(date: Date.new(2026, 9, 29), created_at: Date.new(2026, 10, 2), updated_at: Date.new(2026, 10, 2), views: 1, file_id: 'f2', user_id: 1)
    run_task('hyku:purge_cached_stats')

    expect(FileViewStat.exists?(stat.id)).to be false
  end

  it 'deletes earlier stats refreshed on or after SINCE' do
    marker = FileViewStat.create!(date: Date.new(2026, 9, 29), created_at: Date.new(2026, 9, 1), updated_at: Date.new(2026, 10, 2), views: 0, file_id: 'f3', user_id: 1)
    run_task('hyku:purge_cached_stats')

    expect(FileViewStat.exists?(marker.id)).to be false
  end

  it 'purges the shared UserStat table once, not per tenant' do
    output = run_task('hyku:purge_cached_stats')

    expect(output).to include('all tenants: deleted 1 UserStat rows')
    expect(output).not_to include('example.test: deleted 1 UserStat rows')
  end

  it 'deletes nothing on a dry run' do
    allow(ENV).to receive(:fetch).with('DRY_RUN', false).and_return('true')

    expect(run_task('hyku:purge_cached_stats')).to include 'example.test: would delete 1 FileViewStat rows'
    expect(FileViewStat.count).to eq 2
  end

  it 'requires SINCE' do
    allow(ENV).to receive(:fetch).with('SINCE').and_call_original

    expect { run_task('hyku:purge_cached_stats') }.to raise_error(KeyError)
  end
end
