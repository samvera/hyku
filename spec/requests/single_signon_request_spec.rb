# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "SingleSignons", type: :request, singletenant: true do
  describe "GET single_signon#index" do
    describe "with no IdentityProviders" do
      it "redirects to sign in" do
        get "/single_signon"
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "with an IdentityProvider" do
      before do
        IdentityProvider.create(name: 'fake', provider: 'saml')
      end

      it "renders succes" do
        get "/single_signon"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
