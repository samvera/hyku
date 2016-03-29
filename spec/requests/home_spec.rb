require 'rails_helper'

RSpec.describe 'Home page', type: :request do
  before do
    allow_any_instance_of(ActiveFedora::Fedora).to receive(:init_base_path)
  end

  context 'without a current tenant' do
    before do
      allow(Settings).to receive(:multitenant).and_return(true)
    end

    describe 'GET /' do
      it 'redirects to the accounts landing page' do
        get root_path
        expect(response).to redirect_to(accounts_path)
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
