# frozen_string_literal: true

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      head :ok
    end
  end

  describe '#current_account' do
    before do
      allow(controller).to receive(:multitenant?).and_return(true)
      allow(Account).to receive(:from_request).and_return(nil)
    end

    it 'does not build an fcrepo endpoint when Wings is disabled' do
      allow(Hyrax.config).to receive(:disable_wings).and_return(true)

      account = controller.send(:current_account)

      expect(account.association(:fcrepo_endpoint).target).to be_nil
    end

    it 'builds an fcrepo endpoint when Wings is enabled' do
      allow(Hyrax.config).to receive(:disable_wings).and_return(false)

      account = controller.send(:current_account)

      expect(account.association(:fcrepo_endpoint).target).to be_present
    end
  end
end
