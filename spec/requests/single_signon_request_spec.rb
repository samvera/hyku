# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "SingleSignons", type: :request do
  describe "GET single_signon#index" do
    it "returns http success" do
      get "/single_signon"
      expect(response).to have_http_status(:success)
    end
  end
end
