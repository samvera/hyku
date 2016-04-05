require 'rails_helper'

RSpec.describe ApplicationServiceStatusController, type: :controller do

  describe "GET #application_service_status_dashboard" do
    it "returns http success" do
      get :application_service_status_dashboard
      expect(response).to have_http_status(:success)
    end
  end

end
