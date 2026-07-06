# frozen_string_literal: true

class AddDemoResetFieldsToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :last_reset_at, :datetime
    add_column :accounts, :demo_tenant_snapshot, :jsonb
  end
end
