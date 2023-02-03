class AddSortValueToRoles < ActiveRecord::Migration[5.2]
  def change
    add_column :roles, :sort_value, :integer
  end
end
