class AddLastEmailedAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :last_emailed_at, :datetime unless column_exists?(:users, :last_emailed_at)
  end
end
