# frozen_string_literal: true

RSpec.describe SitesController, type: :controller, singletenant: true do
  before { sign_in user }

  context 'with an unprivileged user' do
    let(:user) { create(:user) }

    describe "POST #update" do
      it "denies the request" do
        post :update
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  context 'with an administrator' do
    let(:user) { create(:admin) }

    context 'selecting a theme' do
      it 'sets the home, search, and show themes' do
        expect(Site.instance.home_theme).to be nil
        post :update, params: { site: { home_theme: 'home page theme', search_theme: 'gallery', show_theme: 'show page theme' } }
        expect(Site.instance.home_theme).to eq 'home page theme'
        expect(Site.instance.search_theme).to eq 'gallery'
        expect(Site.instance.show_theme).to eq 'show page theme'
        expect(flash[:notice]).to include('The appearance was successfully updated')
      end
    end
  end
end
