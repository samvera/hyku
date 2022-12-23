# frozen_string_literal: true

RSpec.describe "User roles", type: :request, singletenant: true, clean: true do
  let(:tenant_user_attributes) { attributes_for(:user) }
  let!(:group_1) { FactoryBot.create(:group) }

  context 'within a tenant' do
    context 'a registered user with no role' do
      let(:user) { FactoryBot.create(:user) }

      before do
        login_as(user)
      end

      it 'can access the users profile' do
        get "/dashboard/profiles/#{user.email.gsub('.', '-dot-')}"
        expect(response.status).to eq(200)
        expect(response).to have_http_status(:success)
      end

      it 'can access the users notifications' do
        get "/notifications"
        expect(response.status).to eq(200)
        expect(response).to have_http_status(:success)
      end

      it 'can access the users transfers' do
        get "/dashboard/transfers"
        expect(response.status).to eq(200)
        expect(response).to have_http_status(:success)
      end

      it 'can access the users manage proxies' do
        get "/proxies"
        expect(response.status).to eq(200)
        expect(response).to have_http_status(:success)
      end
    end

    context 'an unregistered user' do
      let(:user_params) do
        {
          user: {
            email: tenant_user_attributes[:email],
            password: tenant_user_attributes[:password],
            password_confirmation: tenant_user_attributes[:password]
          }
        }
      end

      it 'can sign up' do
        expect { post "/users", params: user_params }
          .to change(User, :count).by(1)
        expect(response.status).to eq(302)
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  context 'a registered user with user_manager role' do
    let(:user_manager) { FactoryBot.create(:user_manager) }

    before do
      FactoryBot.create(:user, email: 'user@example.com', display_name: 'Regular User')
      login_as(user_manager, scope: :user)
    end

    it 'can access the users index' do
      get '/users'
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'can access a users showpage' do
      get '/users/user@example-dot-com'
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'can access a users profile' do
      get '/dashboard/profiles/user@example-dot-com'
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'can access a users profile edit' do
      get '/dashboard/profiles/user@example-dot-com/edit'
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'can access manage groups' do
      get '/admin/groups'
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'can access manage users' do
      get '/admin/users'
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'can access/edit manage groups user tab' do
      get "/admin/groups/#{group_1.id}/users"
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'can access/edit manage groups role tab' do
      get "/admin/groups/#{group_1.id}/roles"
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'can access/edit manage groups remove tab' do
      get "/admin/groups/#{group_1.id}/remove"
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end
  end

  context 'a registered user with user_reader role' do
    let(:user_reader) { FactoryBot.create(:user_reader) }

    before do
      FactoryBot.create(:user, email: 'user@example.com', display_name: 'Regular User')
      login_as(user_reader, scope: :user)
    end

    it 'can access the users index' do
      get '/users'
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'can access a users showpage' do
      get '/users/user@example-dot-com'
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'can access a users profile' do
      get '/dashboard/profiles/user@example-dot-com'
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'cannot access a users profile edit' do
      get '/dashboard/profiles/user@example-dot-com/edit'
      expect(response.status).to eq(401)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'can access manage groups' do
      get '/admin/groups'
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'can access manage users' do
      get '/admin/users'
      expect(response.status).to eq(200)
      expect(response).to have_http_status(:success)
    end

    it 'cannot access/edit manage groups user tab' do
      get "/admin/groups/#{group_1.id}/users"
      expect(response.status).to eq(401)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'cannot access/edit manage groups role tab' do
      get "/admin/groups/#{group_1.id}/roles"
      expect(response.status).to eq(401)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'cannot access/edit manage groups remove tab' do
      get "/admin/groups/#{group_1.id}/remove"
      expect(response.status).to eq(302)
      expect(response).to have_http_status(:redirect)
    end
  end
end
