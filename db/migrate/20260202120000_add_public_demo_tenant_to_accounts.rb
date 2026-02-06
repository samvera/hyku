# frozen_string_literal: true

class AddPublicDemoTenantToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :public_demo_tenant, :boolean, default: false, null: false
  end
end
