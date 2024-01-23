# This migration comes from iiif_print (originally 20190107165909)
class CreateIiifPrintIngestFileRelations < ActiveRecord::Migration[5.0]
  def change
    unless table_exists?(:iiif_print_ingest_file_relations)
      create_table :iiif_print_ingest_file_relations do |t|
        t.string :file_path
        t.string :derivative_path

        t.timestamps
      end
      add_index :iiif_print_ingest_file_relations, :file_path
    end
  end
end
