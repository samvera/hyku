class AddDirectoryImageAltTextToSites < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :directory_image_alt_text, :string
  end
end
