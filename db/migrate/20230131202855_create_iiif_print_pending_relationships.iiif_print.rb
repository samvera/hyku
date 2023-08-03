# This migration comes from iiif_print (originally 20230109000000)
class CreateIiifPrintPendingRelationships < ActiveRecord::Migration[5.1]
  def change
    unless table_exists?(:iiif_print_pending_relationships)
      create_table :iiif_print_pending_relationships do |t|
        t.string :child_title, null: false
        t.string :parent_id, null: false
        t.string :child_order, null: false
        t.timestamps
      end
      add_index :iiif_print_pending_relationships, :parent_id
    end
  end
end
