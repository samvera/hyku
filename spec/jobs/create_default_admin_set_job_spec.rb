# frozen_string_literal: true

RSpec.describe CreateDefaultAdminSetJob do
  let!(:account) { FactoryBot.create(:account) }

  describe '#perform' do
    it 'creates a new admin set for an account', clean: true do
      expect { described_class.perform_now(account) }.to change(AdminSet, :count).by(1)
    end
  end
end
