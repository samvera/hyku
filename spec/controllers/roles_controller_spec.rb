RSpec.describe RolesController, type: :controller do
  before do
    sign_in user
  end

  let(:valid_attributes) do
    { site_roles: ['admin'] }
  end

  context 'with an unprivileged user' do
    let(:user) { create(:user) }

    describe "GET #edit" do
      it "denies the request" do
        get :index
        expect(response).not_to have_http_status(:ok)
      end
    end

    describe "PUT #update" do
      it "denies the request" do
        put :update, params: { id: user.id }
        expect(response).not_to have_http_status(:created)
      end
    end
  end

  context 'with an administrator' do
    let(:user) { FactoryBot.create(:admin) }

    describe "GET #index" do
      before do
        # it should not return guest users
        create(:user, guest: true)
      end

      it "assigns the users as @users" do
        get :index
        expect(assigns(:users)).to match_array [user]
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) do
          { site_roles: ['admin', 'superadmin'] }
        end

        it "updates the requested role" do
          put :update, params: { id: user.id, user: new_attributes }
          user.reload
          expect(user.site_roles.pluck(:name)).to match_array ['admin', 'superadmin']
        end

        it "assigns the requested user as @user" do
          put :update, params: { id: user.id, user: valid_attributes }
          expect(assigns(:user)).to eq(user)
        end

        it "redirects to the site roles" do
          put :update, params: { id: user.id, user: valid_attributes }
          expect(response).to redirect_to(site_roles_path)
        end
      end
    end
  end
end
