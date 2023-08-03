class CreateAuthProviders < ActiveRecord::Migration[5.2]
  def change
    create_table :auth_providers do |t|
      t.string :provider
      t.string :client_id
      t.string :client_secret
      t.string :idp_sso_service_url
      t.integer :account_id
      t.timestamps
    end
  end
end