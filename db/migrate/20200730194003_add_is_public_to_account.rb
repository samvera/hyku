class AddIsPublicToAccount < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :is_public, :boolean, default: false

    Account.reset_column_information
    Account.update_all(is_public: true)
  end
end
