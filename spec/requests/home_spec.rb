RSpec.describe 'Home page', type: :request do
  context 'with multitenancy' do
    describe 'GET /' do
      context "on the primary host" do
        before { host! 'localhost' }
        it 'redirects to the accounts landing page' do
          get root_path
          expect(response).to have_http_status(200)
        end
      end

      context "on a subhost" do
        before { host! 'foo.bar.com' }
        it 'raises a 404' do
          expect { get root_path }.to raise_error(ActionController::RoutingError)
        end
      end
    end
  end

  describe 'GET /' do
    it 'works! (now write some real specs)' do
      get root_path
      expect(response).to have_http_status(200)
    end
  end
end
