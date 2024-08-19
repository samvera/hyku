# frozen_string_literal: true

require 'freyja/persister'
RSpec.describe LeaseAutoExpiryJob, clean: true do
  before do
    ActiveJob::Base.queue_adapter = :test
    FactoryBot.create(:group, name: "public")
  end

  after do
    clear_enqueued_jobs
  end

  let(:past_date) { 2.days.ago }
  let(:future_date) { 2.days.from_now }

  let(:account) { create(:account_with_public_schema) }

  let(:leased_work) do
    build(:work, lease_expiration_date: future_date.to_s,
                 visibility_during_lease: 'open',
                 visibility_after_lease: 'restricted').tap do |work|
      work.lease_visibility!
      work.save(validate: false)
    end
  end

  let(:work_with_expired_lease) do
    build(:work, lease_expiration_date: past_date.to_s,
                 visibility_during_lease: 'open',
                 visibility_after_lease: 'restricted',
                 visibility: 'open').tap do |work|
      work.save(validate: false)
    end
  end

  let(:file_set_with_expired_lease) do
    build(:file_set, lease_expiration_date: past_date.to_s,
                     visibility_during_lease: 'open',
                     visibility_after_lease: 'restricted',
                     visibility: 'open').tap do |file_set|
      file_set.save(validate: false)
    end
  end

  describe '#reenqueue' do
    it 'Enques an LeaseExpiryJob after perform' do
      switch!(account)
      expect { LeaseAutoExpiryJob.perform_now }.to have_enqueued_job(LeaseAutoExpiryJob)
    end
  end

  describe '#perform' do
    it "Expires the lease on a work with expired lease", active_fedora_to_valkyrie: true do
      expect(work_with_expired_lease).to be_a_kind_of(GenericWork)
      expect(work_with_expired_lease.visibility).to eq('open')

      expect do
        expect do
          ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
          switch!(account)
          LeaseAutoExpiryJob.perform_now
        end.not_to change { work_with_expired_lease.reload.visibility } # because of double combo
      end.to change { GenericWorkResource.find(work_with_expired_lease.id).visibility }
        .from('open')
        .to('restricted')
    end

    it 'Expires leases on file sets with expired leases' do
      expect(file_set_with_expired_lease).to be_a_kind_of(ActiveFedora::Base)
      expect(file_set_with_expired_lease.visibility).to eq('open')
      expect do
        expect do
          ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
          switch!(account)
          LeaseAutoExpiryJob.perform_now
        end.not_to change { file_set_with_expired_lease.reload.visibility } # because of double combo
      end.to change { Hyrax.query_service.find_by(id: file_set_with_expired_lease.id).visibility }
        .from('open')
        .to('restricted')
    end

    it "Does not expire lease when lease is still active", active_fedora_to_valkyrie: true do
      expect(leased_work).to be_a_kind_of(GenericWork)
      expect(leased_work.visibility).to eq('open')

      expect do
        expect do
          ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
          switch!(account)
          LeaseAutoExpiryJob.perform_now
        end.not_to change { leased_work.reload.visibility } # because of double combo
      end.not_to change { GenericWorkResource.find(leased_work.id).visibility }
        .from('open')
    end
  end
end
