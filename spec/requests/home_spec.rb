# frozen_string_literal: true

RSpec.describe 'Home page', type: :request do
  context 'with multitenancy', multitenant: true do
    describe 'GET /' do
      context 'on the primary host' do
        before { host!(ENV['WEB_HOST'] || 'localhost') }

        it 'redirects to the accounts landing page' do
          get root_path
          expect(response).to have_http_status(:ok)
        end
      end

      context 'on an unknown subhost' do
        before { host! 'mystery.localhost' }

        it 'raises a 404' do
          expect { get root_path }.to raise_error(ActionController::RoutingError)
        end
      end
    end
  end

  context 'with singletenancy', singletenant: true do
    describe 'GET /' do
      it 'fields the request' do
        get root_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
