# frozen_string_literal: true

RSpec.describe 'Insitution visiblity work access', type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }
  let(:account2) { create(:account) }
  let(:tenant_user_attributes) { attributes_for(:user) }
  let(:tenant2_user_attributes) { attributes_for(:user) }
  let(:work) { create(:work, visibility: 'authenticated') }

  let(:tenant_user) do
    post "http://#{account.cname}/users", params: { user: {
      display_name: tenant_user_attributes[:name],
      email: tenant_user_attributes[:email],
      password: tenant_user_attributes[:password],
      password_confirmation: tenant_user_attributes[:password]
    } }
    User.last
  end

  let(:tenant2_user) do
    post "http://#{account2.cname}/users", params: { user: {
      display_name: tenant2_user_attributes[:name],
      email: tenant2_user_attributes[:email],
      password: tenant2_user_attributes[:password],
      password_confirmation: tenant2_user_attributes[:password]
    } }
    User.last
  end

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account:)
      work
    end
    Apartment::Tenant.create(account2.tenant)
    Apartment::Tenant.switch(account2.tenant) do
      Site.update(account: account2)
    end

    # sign up user 1 at account 1
    tenant_user
    # and sign up user 2 at account 2
    tenant2_user
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
    Apartment::Tenant.drop(account2.tenant)
  end

  describe 'as an end-user' do
    it 'allows access for users of the tenant' do
      login_as tenant_user, scope: :user
      get "http://#{account.cname}/concern/generic_works/#{work.id}"

      expect(response.status).to eq(200)
    end

    it 'does not allow access for users of other tenants' do
      login_as tenant2_user, scope: :user
      get "http://#{account.cname}/concern/generic_works/#{work.id}"

      expect(response.status).to eq(401)
    end
  end

  describe 'when a user is invited' do
    before do
      Apartment::Tenant.switch(account.tenant) do
        site = Site.instance
        tenant2_user.add_role('manager', site)
      end
    end

    it 'now allows access for users of the tenant' do
      login_as tenant2_user, scope: :user
      get "http://#{account.cname}/concern/generic_works/#{work.id}"

      expect(response.status).to eq(200)
    end
  end
end
