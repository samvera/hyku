# This migration comes from qa (originally 20130917201026)
class CreateQaMeshTree < ActiveRecord::Migration[4.2]
  def change
    create_table :qa_mesh_trees do |t|
      t.string :term_id
      t.string :tree_number
    end
    add_index :qa_mesh_trees, :term_id
    add_index :qa_mesh_trees, :tree_number
  end
end
