# frozen_string_literal: true

RSpec.describe CreateDefaultAdminSetJob do
  let!(:account) { FactoryBot.create(:account) }

  describe '#perform' do
    it 'creates a new admin set for an account', clean: true do
      expect do
        described_class.perform_now(account)
      end.to change { Hyrax.query_service.count_all_of_model(model: Hyrax.config.admin_set_class) } .by(1)
    end
  end
end
