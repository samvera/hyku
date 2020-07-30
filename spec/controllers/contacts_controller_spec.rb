# frozen_string_literal: true

RSpec.describe ContactsController, type: :controller do
  before do
    sign_in user
  end

  let(:valid_attributes) do
    {
      contact_email: 'test@example.com'
    }
  end

  let(:invalid_attributes) do
    { contact_email: nil }
  end

  context 'with an unprivileged user' do
    let(:user) { FactoryBot.create(:user) }

    describe "GET #edit" do
      it "denies the request" do
        get :edit
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "PUT #update" do
      it "denies the request" do
        put :update, params: { site: valid_attributes }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  context 'with an administrator' do
    let(:user) { FactoryBot.create(:admin) }

    describe "GET #edit" do
      it "assigns the requested site as @site" do
        get :edit, params: {}
        expect(assigns(:site)).to eq(Site.instance)
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) do
          {
            contact_email: 'new@test.com'
          }
        end

        it "updates the requested site" do
          put :update, params: { site: new_attributes }
          Site.reload
          expect(Site.contact_email).to eq "new@test.com"
        end

        it "assigns the requested site as @site" do
          put :update, params: { site: valid_attributes }
          expect(assigns(:site)).to eq(Site.instance)
        end

        it "redirects to the site" do
          put :update, params: { site: valid_attributes }
          expect(response).to redirect_to(edit_site_contact_path)
        end
      end

      context "with invalid params" do
        it "assigns the site as @site" do
          put :update, params: { site: invalid_attributes }
          expect(assigns(:site)).to eq(Site.instance)
        end

        it "redirects to the 'edit' template" do
          put :update, params: { site: invalid_attributes }
          expect(response).to redirect_to(edit_site_contact_path)
        end
      end
    end
  end
end
