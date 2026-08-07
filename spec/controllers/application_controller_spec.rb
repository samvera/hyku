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
    let(:env_user) { nil }
    let(:env_password) { nil }

    before do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(controller).to receive(:staging?).and_return(true)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('HYKU_BASIC_AUTH_USER', nil).and_return(env_user)
      allow(ENV).to receive(:fetch).with('HYKU_BASIC_AUTH_PASSWORD', nil).and_return(env_password)
    end

    def http_login(username, password)
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    end

    context 'when credentials are configured via ENV' do
      let(:env_user) { 'gatekeeper' }
      let(:env_password) { 'not-a-default' }

      it 'grants access with the configured credentials' do
        http_login('gatekeeper', 'not-a-default')
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'denies access with the historical default credentials' do
        http_login('samvera', 'hyku')
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when no credentials are configured' do
      it 'fails closed and denies the historical default credentials' do
        http_login('samvera', 'hyku')
        get :index
        expect(response).to have_http_status(:unauthorized)
      end

      context 'when in the development environment' do
        before { allow(Rails.env).to receive(:development?).and_return(true) }

        it 'still accepts the historical default credentials' do
          http_login('samvera', 'hyku')
          get :index
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'when the controller attributes are set' do
      let(:env_user) { 'gatekeeper' }
      let(:env_password) { 'not-a-default' }

      before do
        controller.http_basic_auth_username = 'attribute-user'
        controller.http_basic_auth_password = 'attribute-pass'
      end

      it 'prefers the attribute values over the ENV values' do
        http_login('attribute-user', 'attribute-pass')
        get :index
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
