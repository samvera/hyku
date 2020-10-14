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
          {
            logo_image: 'image.jpg',
            banner_image: 'image.jpg',
            directory_image: 'image.jpg',
            default_collection_image: 'image.jpg',
            default_work_image: 'image.jpg',
            link_color: '#2e74b2',
            body_font: 'Helvetica Neue, Helvetica, Arial, sans-serif',
            custom_css_block: '/* custom stylesheet */'
          }
        end

        it 'sets a logo image' do
          expect(Site.instance.logo_image?).to be false
          f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
          post :update, params: { admin_appearance: { logo_image: f } }
          expect(response).to redirect_to(hyrax.admin_appearance_path(locale: 'en'))
          expect(flash[:notice]).to include('The appearance was successfully updated')
          expect(Site.instance.logo_image?).to be true
        end

        it "sets a banner image" do
          expect(Site.instance.banner_image?).to be false
          f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
          post :update, params: { admin_appearance: { banner_image: f } }
          expect(response).to redirect_to(hyrax.admin_appearance_path(locale: 'en'))
          expect(flash[:notice]).to include("The appearance was successfully updated")
          expect(Site.instance.banner_image?).to be true
        end

        it "sets a directory image" do
          expect(Site.instance.directory_image?).to be false
          f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
          post :update, params: { admin_appearance: { directory_image: f } }
          expect(response).to redirect_to(hyrax.admin_appearance_path(locale: 'en'))
          expect(flash[:notice]).to include("The appearance was successfully updated")
          expect(Site.instance.directory_image?).to be true
        end

        context 'for default collection image' do
          it 'sets an image' do
            expect(Site.instance.default_collection_image?).to be false
            f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
            post :update, params: { admin_appearance: { default_collection_image: f } }
            expect(response).to redirect_to(hyrax.admin_appearance_path(locale: 'en'))
            expect(flash[:notice]).to include('The appearance was successfully updated')
            expect(Site.instance.default_collection_image?).to be true
          end

          it 'enqueues two jobs' do
            expect(ReindexCollectionsJob).to receive(:perform_later).once
            expect(ReindexAdminSetsJob).to receive(:perform_later).once

            f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
            post :update, params: { admin_appearance: { default_collection_image: f } }
          end
        end

        context 'for default work image' do
          it 'sets an image' do
            expect(Site.instance.default_work_image?).to be false
            f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
            post :update, params: { admin_appearance: { default_work_image: f } }
            expect(response).to redirect_to(hyrax.admin_appearance_path(locale: 'en'))
            expect(flash[:notice]).to include('The appearance was successfully updated')
            expect(Site.instance.default_work_image?).to be true
          end

          it 'enqueues one jobs' do
            expect(ReindexWorksJob).to receive(:perform_later).once

            f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
            post :update, params: { admin_appearance: { default_work_image: f } }
          end
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
