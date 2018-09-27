class AddDefaultCollectionImageToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :default_collection_image, :string
    add_column :sites, :default_work_image, :string
  end
end
