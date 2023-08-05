FactoryBot.define do
  factory :identity_provider, class: 'IdentityProvider' do
    name { 'SAML Test' }
    provider { 'saml' }
    options { {} }
  end
end
