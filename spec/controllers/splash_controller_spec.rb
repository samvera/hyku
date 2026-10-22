# frozen_string_literal: true

RSpec.describe SplashController, flexible: :either do
  describe 'get index' do
    it 'is successful' do
      get :index
      expect(response).to be_successful
    end
  end
end
