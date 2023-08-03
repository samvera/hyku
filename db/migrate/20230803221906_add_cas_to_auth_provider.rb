class AddCasToAuthProvider < ActiveRecord::Migration[5.2]
  def change
    add_column :auth_providers, :cas_host, :string
    add_column :auth_providers, :cas_login_url, :string
  end
end
