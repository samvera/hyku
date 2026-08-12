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

  describe '#authenticate_if_needed' do
    before do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(controller).to receive(:staging?).and_return(true)
    end

    def http_login(username, password)
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    end

    it 'grants access with the default credentials' do
      http_login('samvera', 'hyku')
      get :index
      expect(response).to have_http_status(:ok)
    end

    it 'denies access with wrong credentials' do
      http_login('intruder', 'nope')
      get :index
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when the credential attributes are overridden' do
      before do
        controller.http_basic_auth_username = 'gatekeeper'
        controller.http_basic_auth_password = 'not-a-default'
      end

      it 'grants access with the overridden credentials' do
        http_login('gatekeeper', 'not-a-default')
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'denies access with the default credentials' do
        http_login('samvera', 'hyku')
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
