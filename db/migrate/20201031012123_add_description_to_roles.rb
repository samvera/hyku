class AddDescriptionToRoles < ActiveRecord::Migration[5.2]
  def change
    add_column :roles, :description, :text
  end
end
