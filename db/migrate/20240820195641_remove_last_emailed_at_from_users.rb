class RemoveLastEmailedAtFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :last_emailed_at, :datetime if column_exists?(:users, :last_emailed_at)
  end
end
