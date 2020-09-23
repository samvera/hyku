# frozen_string_literal: true

RSpec.describe LeaseAutoExpiryJob do
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    clear_enqueued_jobs
  end

  let(:past_date) { 2.days.ago }
  let(:future_date) { 2.days.from_now }

  let(:account) { create(:account) }

  let!(:leased_work) do
    build(:work, lease_expiration_date: future_date.to_s,
                 visibility_during_lease: 'open',
                 visibility_after_lease: 'restricted').tap do |work|
      work.lease_visibility!
      work.save(validate: false)
    end
  end

  let!(:work_with_expired_lease) do
    build(:work, lease_expiration_date: past_date.to_s,
                 visibility_during_lease: 'open',
                 visibility_after_lease: 'restricted',
                 visibility: 'open').tap do |work|
      work.save(validate: false)
    end
  end

  let!(:file_set_with_expired_lease) do
    build(:file_set, lease_expiration_date: past_date.to_s,
                     visibility_during_lease: 'open',
                     visibility_after_lease: 'restricted',
                     visibility: 'open').tap do |file_set|
      file_set.save(validate: false)
    end
  end

  describe '#reenqueue' do
    it 'Enques an LeaseExpiryJob after perform' do
      expect { LeaseAutoExpiryJob.perform_now(account) }.to have_enqueued_job(LeaseAutoExpiryJob)
    end
  end

  describe '#perform' do
    it "Expires the lease on a work with expired lease" do
      expect(work_with_expired_lease.visibility).to eq('open')
      ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
      LeaseAutoExpiryJob.perform_now(account)
      work_with_expired_lease.reload
      expect(work_with_expired_lease.visibility).to eq('restricted')
    end

    it 'Expires leases on file sets with expired leases' do
      expect(file_set_with_expired_lease.visibility).to eq('open')
      ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
      LeaseAutoExpiryJob.perform_now(account)
      file_set_with_expired_lease.reload
      expect(file_set_with_expired_lease.visibility).to eq('restricted')
    end

    it "Does not expire lease when lease is still active" do
      expect(leased_work.visibility).to eq('open')
      ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
      LeaseAutoExpiryJob.perform_now(account)
      expect(leased_work.visibility).to eq('open')
    end
  end
end
