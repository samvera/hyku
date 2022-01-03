class AddSearchOnlyToAccount < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :search_only, :boolean, default: false
  end
end
