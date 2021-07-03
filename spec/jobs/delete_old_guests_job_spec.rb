# frozen_string_literal: true

RSpec.describe DeleteOldGuestsJob do
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    clear_enqueued_jobs
  end

  let(:past_date) { 8.days.ago }

  let(:old_user) { create(:user, guest: false, created_at: past_date, updated_at: past_date) }
  let(:old_guest) { create(:user, guest: true, created_at: past_date, updated_at: past_date) }
  let(:new_user) { create(:user, guest: false) }
  let(:new_guest) { create(:user, guest: true) }

  describe '#reenqueue' do
    it 'Enques an DeleteOldGuestsJob after perform' do
      expect { DeleteOldGuestsJob.perform_now }.to have_enqueued_job(DeleteOldGuestsJob)
    end
  end

  describe '#perform' do
    it "Removes only guests older than 7 days" do
      expect(old_user).to be
      expect(old_guest).to be
      expect(new_user).to be
      expect(new_guest).to be
      ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
      expect { DeleteOldGuestsJob.perform_now }.to change { User.unscope(:where).count }.from(4).to(3)
      expect(User.unscope(:where).find_by(id: old_user.id)).to be
      expect(User.unscope(:where).find_by(id: old_guest)).not_to be
      expect(User.unscope(:where).find_by(id: new_user)).to be
      expect(User.unscope(:where).find_by(id: new_guest)).to be
    end
  end
end
