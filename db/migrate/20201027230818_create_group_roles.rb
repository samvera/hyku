class CreateGroupRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :group_roles do |t|
      t.belongs_to :role
      t.belongs_to :group
      t.timestamps
    end
  end
end
