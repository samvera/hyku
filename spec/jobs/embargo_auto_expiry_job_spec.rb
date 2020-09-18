RSpec.describe EmbargoAutoExpiryJob do
  include ActiveJob::TestHelper

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    clear_enqueued_jobs
  end

  sidekiq_file = File.join(Rails.root, "config", "schedule.yml")
  schedule = YAML.load_file(sidekiq_file)["embargo_auto_expiry_job"]

  let(:past_date) { 2.days.ago }
  let(:future_date) { 2.days.from_now }

  let!(:embargoed_work) do
   build(:work, embargo_release_date: future_date.to_s, visibility_during_embargo: 'restricted', visibility_after_embargo: 'open').tap do |work|
     work.save(validate: false)
   end
 end

  let!(:work_with_expired_embargo) do
   build(:work, embargo_release_date: past_date.to_s, visibility_during_embargo: 'restricted', visibility_after_embargo: 'open').tap do |work|
     work.save(validate: false)
   end
 end

 let!(:file_set_with_expired_embargo) do
    build(:file_set, embargo_release_date: past_date.to_s, visibility_during_embargo: 'restricted', visibility_after_embargo: 'open').tap do |file_set|
      file_set.save(validate: false)
    end
  end

  it 'is scheduled to run everyday at 00:00' do
    cron = schedule["cron"]
    expect(Fugit.do_parse(cron).original).to eq("0 0 * * *")
  end


  describe '#perform' do
    it "Enques a EmbargoExpiryJob" do
      expect { EmbargoAutoExpiryJob.perform_now}.to have_enqueued_job(EmbargoExpiryJob)
    end

    it "Expires the Embargo on a work with expired Embargo" do
      expect(work_with_expired_embargo.visibility).to eq('restricted')
      ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
      EmbargoAutoExpiryJob.perform_now
      work_with_expired_embargo.reload
      expect(work_with_expired_embargo.visibility).to eq('open')
    end

    it 'Expires embargos on file sets with expired embargos' do
      expect(file_set_with_expired_embargo.visibility).to eq('restricted')
      ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
      EmbargoAutoExpiryJob.perform_now
      file_set_with_expired_embargo.reload
      expect(file_set_with_expired_embargo.visibility).to eq('open')
    end

    it "Does not expire embargo when embargo is still active" do
      expect(embargoed_work.visibility).to eq('restricted')
      ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
      EmbargoAutoExpiryJob.perform_now
      embargoed_work.reload
      expect(embargoed_work.visibility).to eq('restricted')
    end
  end
end
