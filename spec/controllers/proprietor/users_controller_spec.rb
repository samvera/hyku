# frozen_string_literal: true

RSpec.describe Proprietor::UsersController, type: :controller, multitenant: true do
  let(:user) {}
  let(:valid_attributes) do
    attributes_for(:user)
  end

  let(:invalid_attributes) do
    attributes_for(:user, email: 'not_an_email')
  end

  before do
    sign_in user if user
  end

  context 'as an anonymous user' do
    describe "GET #new" do
      it "is unauthorized" do
        get :new
        expect(response).to be_redirect
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "is unauthorized" do
          expect do
            post :create, params: { user: valid_attributes }
          end.not_to change(User, :count)
          expect(response).to be_redirect
        end
      end
    end
  end

  context 'as an admin of a site' do
    let(:user) { FactoryBot.create(:admin) }
    let(:account) { FactoryBot.create(:account) }

    before do
      Site.update(account:)
    end

    describe "GET #index" do
      it "is authorized" do
        get :index
        expect(response).to be_successful
      end
    end

    describe "GET #show" do
      it "assigns the requested user as @user" do
        get :show, params: { id: user.to_param }
        expect(assigns(:user)).to eq(user)
      end
    end

    describe "GET #edit" do
      it "assigns the requested user as @user" do
        get :edit, params: { id: user.to_param }
        expect(assigns(:user)).to eq(user)
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) do
          {
            facebook_handle: "test",
            twitter_handle: "test",
            googleplus_handle: "test",
            display_name: "test",
            address: "test",
            department: "test",
            title: "test",
            office: "test",
            chat_id: "test",
            website: "test",
            affiliation: "test",
            telephone: "test",
            group_list: "test",
            linkedin_handle: "test",
            orcid: "https://orcid.org/0000-0000-0000-0000",
            arkivo_token: "test",
            arkivo_subscription: "test",
            zotero_token: "test",
            zotero_userid: "test",
            preferred_locale: 'en'
          }
        end

        it "updates the requested user" do
          allow(Apartment::Tenant).to receive(:switch).with(account.tenant) do |&block|
            block.call
          end
          put :update, params: { id: user.to_param, user: new_attributes }
          user.reload
          new_attributes.each do |key, value|
            expect(user.send(key)).to eq(value), "expected #{key} to be #{value}, got #{user.send(key)}"
          end
          expect(response).to redirect_to(proprietor_users_path)
        end

        it "assigns the requested user as @user" do
          put :update, params: { id: user.to_param, user: valid_attributes }
          expect(assigns(:user)).to eq(user)
        end
      end

      context "with invalid params" do
        it "assigns the user as @user" do
          put :update, params: { id: user.to_param, user: invalid_attributes }
          expect(assigns(:user)).to eq(user)
        end

        it "re-renders the 'edit' template" do
          put :update, params: { id: user.to_param, user: invalid_attributes }
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the user and redirects to the users list" do
        expect_any_instance_of(User).to receive(:destroy).and_return(true)
        delete :destroy, params: { id: user.to_param }
        expect(response).to redirect_to(proprietor_users_url)
      end
    end
  end

  context 'as a superadmin' do
    let(:user) { FactoryBot.create(:superadmin) }

    describe "GET #index" do
      it "assigns all users as @users" do
        get :index
        expect(assigns(:users)).to include user
        expect(response).to render_template("layouts/proprietor")
      end
    end

    describe "GET #show" do
      it "assigns the requested user as @user" do
        get :show, params: { id: user.to_param }
        expect(assigns(:user)).to eq(user)
      end
    end

    describe "DELETE #destroy" do
      it "destroys the user and redirects to the users list" do
        expect_any_instance_of(User).to receive(:destroy).and_return(true)
        delete :destroy, params: { id: user.to_param }
        expect(response).to redirect_to(proprietor_users_url)
      end
    end
  end
end
