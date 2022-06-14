# This migration comes from sufia (originally 20161021175854)
class CreatePermissionTemplate < ActiveRecord::Migration[4.2]
  def change
    create_table :permission_templates do |t|
      t.string :admin_set_id
      t.string :visibility
      t.timestamps
    end
    add_index :permission_templates, :admin_set_id
  end
end
