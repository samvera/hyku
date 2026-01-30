# frozen_string_literal: true
class AddSandboxToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :sandbox, :boolean, default: false, null: false
  end
end
