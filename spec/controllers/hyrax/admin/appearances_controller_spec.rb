# frozen_string_literal: true

RSpec.describe Hyrax::Admin::AppearancesController, type: :controller, singletenant: true do
  before { sign_in user }

  routes { Hyrax::Engine.routes }

  context 'with an unprivileged user' do
    let(:user) { create(:user) }

    describe "GET #show" do
      it "denies the request" do
        get :show
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "PUT #update" do
      it "denies the request" do
        put :update
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  context 'with an administrator' do
    let(:user) { create(:admin) }

    describe "GET #show" do
      it "assigns the requested site as @site" do
        get :show, params: {}
        expect(response).to be_successful
      end
    end

    describe "PUT #update" do
      let(:hyrax) { routes.url_helpers }

      context "with valid params" do
        let(:valid_attributes) do
          { banner_image: "image.jpg", directory_image: "image.jpg" }
        end

        it "sets a banner image" do
          expect(Site.instance.banner_image?).to be false
          f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
          post :update, params: { admin_appearance: { banner_image: f } }
          expect(response).to redirect_to(hyrax.admin_appearance_path(locale: 'en'))
          expect(flash[:notice]).to include("The appearance was successfully updated")
          expect(Site.instance.banner_image?).to be true
          expect(Site.instance.banner_image.file.filename).to eq('nypl-hydra-of-lerna.jpg')
        end

        it "replaces an existing banner image" do
          # Set up an initial banner image
          Site.instance.update!(banner_image: fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg'))
          expect(Site.instance.banner_image?).to be true
          original_filename = Site.instance.banner_image.file.filename

          # Upload a different image
          f = fixture_file_upload('/images/world.png', 'image/png')
          post :update, params: { admin_appearance: { banner_image: f } }

          expect(response).to redirect_to(hyrax.admin_appearance_path(locale: 'en'))
          expect(flash[:notice]).to include("The appearance was successfully updated")
          expect(Site.instance.reload.banner_image?).to be true
          expect(Site.instance.banner_image.file.filename).to eq('world.png')
          expect(Site.instance.banner_image.file.filename).not_to eq(original_filename)
        end

        it "sets a directory image" do
          expect(Site.instance.directory_image?).to be false
          f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
          post :update, params: { admin_appearance: { directory_image: f } }
          expect(response).to redirect_to(hyrax.admin_appearance_path(locale: 'en'))
          expect(flash[:notice]).to include("The appearance was successfully updated")
          expect(Site.instance.directory_image?).to be true
        end

        it "redirects to the site" do
          put :update, params: { admin_appearance: valid_attributes }
          expect(response).to redirect_to(hyrax.admin_appearance_path(locale: 'en'))
        end
      end

      context "with invalid params" do
        let(:invalid_attributes) do
          { banner_image: "" }
        end

        it "re-renders the 'show' template" do
          put :update, params: { admin_appearance: invalid_attributes }
          expect(response).to redirect_to(action: "show")
        end
      end
    end
  end
end
