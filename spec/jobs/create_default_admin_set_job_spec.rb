# frozen_string_literal: true

RSpec.describe CreateDefaultAdminSetJob do
  let!(:account) { FactoryBot.create(:account) }

  describe '#perform' do
    it 'creates a new admin set for an account' do
      expect(AdminSet).to receive(:find_or_create_default_admin_set_id).once
      described_class.perform_now(account)
    end
  end
end
