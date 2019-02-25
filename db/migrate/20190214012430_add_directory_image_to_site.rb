class AddDirectoryImageToSite < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, "directory_image", :string
  end
end
