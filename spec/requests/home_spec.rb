RSpec.describe 'Home page', type: :request do
  context 'with multitenancy' do
    describe 'GET /' do
      context 'on the primary host' do
        before { host! 'localhost' }
        it 'redirects to the accounts landing page' do
          get root_path
          expect(response).to have_http_status(200)
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
        expect(response).to have_http_status(200)
      end
    end
  end
end
