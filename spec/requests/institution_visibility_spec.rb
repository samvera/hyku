# frozen_string_literal: true

RSpec.describe 'Insitution visiblity work access', type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }
  let(:account2) { create(:account) }
  let(:tenant_user) { create(:user) }
  let(:tenant2_user) { create(:user) }
  let(:work) { create(:work, visibility: 'authenticated') }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account: account)
      tenant_user
      work
    end
    Apartment::Tenant.create(account2.tenant)
    Apartment::Tenant.switch(account2.tenant) do
      Site.update(account: account2)
      tenant2_user
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
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

  describe 'as a user with a role' do
    let(:tenant_user) do
      u = create(:user)
      u.add_role(:depositor)
      u
    end
    let(:tenant2_user) do
      u = create(:user)
      u.add_role(:depositor)
      u
    end

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
end
