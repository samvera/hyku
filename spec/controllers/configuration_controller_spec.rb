require 'rails_helper'

RSpec.describe ConfigurationController, type: :controller do

  describe "GET #configuration_dashboard" do
    it "returns http success" do
      get :configuration_dashboard
      expect(response).to have_http_status(:success)
    end
  end

end
