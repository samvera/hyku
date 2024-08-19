# This migration comes from iiif_print (originally 20231110163052)
class AddModelDetailsToIiifPrintPendingRelationships < ActiveRecord::Migration[5.2]
  def change
    add_column :iiif_print_pending_relationships, :parent_model, :string unless column_exists?(:iiif_print_pending_relationships, :parent_model)
    add_column :iiif_print_pending_relationships, :child_model, :string  unless column_exists?(:iiif_print_pending_relationships, :child_model)
    add_column :iiif_print_pending_relationships, :file_id, :string  unless column_exists?(:iiif_print_pending_relationships, :file_id)
  end
end
