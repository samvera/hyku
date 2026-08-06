# frozen_string_literal: true

RSpec.describe 'Public demo tenant noindex directives', type: :request, clean: true, multitenant: true do
  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account:)
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  context 'with a public demo tenant' do
    let(:account) { create(:demo_account) }

    it 'sends the X-Robots-Tag header and robots meta tag on the home page' do
      get "http://#{account.cname}/"
      expect(response).to have_http_status(:ok)
      expect(response.headers['X-Robots-Tag']).to eq('noindex, nofollow')
      expect(response.body).to include('<meta name="robots" content="noindex, nofollow">')
    end

    it 'sends the X-Robots-Tag header and robots meta tag on the sign in page' do
      get "http://#{account.cname}/users/sign_in"
      expect(response).to have_http_status(:ok)
      expect(response.headers['X-Robots-Tag']).to eq('noindex, nofollow')
      expect(response.body).to include('<meta name="robots" content="noindex, nofollow">')
    end
  end

  context 'with a regular tenant' do
    let(:account) { create(:account) }

    it 'sends neither the X-Robots-Tag header nor the robots meta tag' do
      get "http://#{account.cname}/"
      expect(response).to have_http_status(:ok)
      expect(response.headers['X-Robots-Tag']).to be_nil
      expect(response.body).not_to include('name="robots"')
    end
  end
end
