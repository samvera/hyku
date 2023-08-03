class ModifyAuthProviders < ActiveRecord::Migration[5.2]
  def change
    # give each auth provider their own unique values.
    remove_column :auth_providers, :client_id, :string
    remove_column :auth_providers, :client_secret, :string
    remove_column :auth_providers, :idp_sso_service_url, :string

    add_column :auth_providers, :oidc_client_id, :string
    add_column :auth_providers, :saml_client_id, :string
    add_column :auth_providers, :oidc_client_secret, :string
    add_column :auth_providers, :saml_client_secret, :string
    add_column :auth_providers, :oidc_idp_sso_service_url, :string
    add_column :auth_providers, :saml_idp_sso_service_url, :string
  end
end
