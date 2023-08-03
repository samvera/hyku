require 'rails_helper'

RSpec.describe AuthProvider, type: :model do
  subject do
    described_class.new(
      provider: 'saml',
      oidc_client_id: 'client_id',
      saml_client_id: 'client_id',
      oidc_client_secret: 'client_secret',
      saml_client_secret: 'client_secret',
      oidc_idp_sso_service_url: 'oidc_idp_sso_service_url',
      saml_idp_sso_service_url: 'saml_idp_sso_service_url',
      account_id: 1
    )
  end

  context 'attributes and validations' do
    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it 'is not valid without a provider' do
      subject.provider = nil
      expect(subject).not_to be_valid
    end

    it 'is not valid without a client_id' do
      subject.oidc_client_id = nil
      subject.saml_client_id = nil
      expect(subject).not_to be_valid
    end

    it 'is not valid without a client_secret' do
      subject.oidc_client_secret = nil
      subject.saml_client_secret = nil
      expect(subject).not_to be_valid
    end
  end

  context 'transactions' do
    it 'has none to begin with' do
      expect(described_class.count).to eq 0
    end

    it 'has one after adding one' do
      AuthProvider.create(
        provider: 'oidc',
        oidc_client_id: 'new oidc_client_id',
        oidc_client_secret: 'new oidc_client_secret',
        oidc_idp_sso_service_url: 'new oidc_idp_sso_service_url',
        account_id: 1
      )
      expect(described_class.count).to eq 1
    end
  end
end
