# frozen_string_literal: true

RSpec.describe EmbargoAutoExpiryJob, clean: true do
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

  let(:embargoed_work) do
    build(:work, embargo_release_date: future_date.to_s,
                 visibility_during_embargo: 'restricted',
                 visibility_after_embargo: 'open').tap do |work|
      work.save(validate: false)
    end
  end

  let(:work_with_expired_embargo) do
    build(:work, embargo_release_date: past_date.to_s,
                 visibility_during_embargo: 'restricted',
                 visibility_after_embargo: 'open').tap do |work|
      work.save(validate: false)
    end
  end

  let(:file_set_with_expired_embargo) do
    build(:file_set, embargo_release_date: past_date.to_s,
                     visibility_during_embargo: 'restricted',
                     visibility_after_embargo: 'open').tap do |file_set|
      file_set.save(validate: false)
    end
  end

  describe '#reenqueue' do
    it 'Enques an EmbargoExpiryJob after perform' do
      switch!(account)
      expect { EmbargoAutoExpiryJob.perform_now }.to have_enqueued_job(EmbargoAutoExpiryJob)
    end
  end

  describe '#perform' do
    it "Expires the Embargo on a work with expired Embargo", active_fedora_to_valkyrie: true do
      expect(work_with_expired_embargo).to be_kind_of(GenericWork)
      expect(work_with_expired_embargo.visibility).to eq('restricted')

      expect do
        ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
        switch!(account)
        EmbargoAutoExpiryJob.perform_now
      end.to change { GenericWorkResource.find(work_with_expired_embargo.id).visibility }
        .from('restricted')
        .to('open')

      # Yes, the underlying Fedora object does not change.  We've migrated it to Valkyrie
      work_with_expired_embargo.reload
      expect(work_with_expired_embargo.visibility).to eq('restricted')
    end

    it 'Expires embargos on file sets with expired embargos' do
      expect(file_set_with_expired_embargo).to be_kind_of(FileSet)
      expect(file_set_with_expired_embargo.visibility).to eq('restricted')
      expect do
        ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
        switch!(account)
        EmbargoAutoExpiryJob.perform_now
      end.to change { Hyrax.query_service.find_by(id: file_set_with_expired_embargo.id).visibility }
        .from('restricted')
        .to('open')

      # Yes, the underlying Fedora object does not change.  We've migrated it to Valkyrie
      file_set_with_expired_embargo.reload
      expect(file_set_with_expired_embargo.visibility).to eq('restricted')
    end

    it "Does not expire embargo when embargo is still active", active_fedora_to_valkyrie: true do
      expect(embargoed_work).to be_kind_of(GenericWork)
      expect(embargoed_work.visibility).to eq('restricted')

      expect do
        ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
        switch!(account)
        EmbargoAutoExpiryJob.perform_now
      end.not_to change { GenericWorkResource.find(embargoed_work.id).visibility }
        .from('restricted')
      embargoed_work.reload
      expect(embargoed_work.visibility).to eq('restricted')
    end
  end
end
