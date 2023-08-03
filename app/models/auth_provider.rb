class AuthProvider < ApplicationRecord
  belongs_to :account

  validates :provider, presence: true

  validates :oidc_client_id, :oidc_client_secret, :oidc_idp_sso_service_url,
            presence: true, if: -> { provider == 'oidc' }

  validates :saml_client_id, :saml_client_secret, :saml_idp_sso_service_url,
            presence: true, if: -> { provider == 'saml' }

  validates :cas_host, :cas_login_urli,
            presence: true, if: -> { provider == 'cas' }

end
