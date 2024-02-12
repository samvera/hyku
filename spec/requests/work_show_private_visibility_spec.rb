# frozen_string_literal: true

RSpec.describe "Users trying to access a Private Work's show page", type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }
  let(:work) { create(:work, visibility: 'restricted') }
  let(:tenant_user_attributes) { attributes_for(:user) }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account:)
      work
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  context 'an unauthenticated user' do
    it 'is redirected to the login view' do
      get "http://#{account.cname}/concern/generic_works/#{work.id}"
      expect(response.status).to eq(302)
    end
  end

  context 'a registered user' do
    before do
      post "http://#{account.cname}/users", params: { user: {
        email: tenant_user_attributes[:email],
        password: tenant_user_attributes[:password],
        password_confirmation: tenant_user_attributes[:password]
      } }
      @tenant_user = User.last
    end

    it 'is not authorized' do
      login_as @tenant_user # rubocop:disable RSpec/InstanceVariable
      get "http://#{account.cname}/concern/generic_works/#{work.id}"
      expect(response.status).to eq(401)
    end
  end

  context 'an admin user' do
    before do
      post "http://#{account.cname}/users", params: { user: {
        email: tenant_user_attributes[:email],
        password: tenant_user_attributes[:password],
        password_confirmation: tenant_user_attributes[:password]
      } }
      @tenant_admin = User.last

      Apartment::Tenant.switch(account.tenant) do
        @tenant_admin.add_role(:admin, Site.instance) # rubocop:disable RSpec/InstanceVariable
      end
    end

    it 'is redirected and then authorized' do
      login_as @tenant_admin # rubocop:disable RSpec/InstanceVariable
      get "http://#{account.cname}/concern/generic_works/#{work.id}"
      expect(response.status).to eq(200)
    end
  end
end
