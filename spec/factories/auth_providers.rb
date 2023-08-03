FactoryBot.define do
  factory :auth_provider, class: 'AuthProvider' do
    provider { 'saml' }
    client_id { 'client_id' }
    client_secret { 'client_secret' }
    idp_sso_service_url { 'idp_sso_service_url' }
    account_id { 1 }
  end
end
