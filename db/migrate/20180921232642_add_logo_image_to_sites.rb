class AddLogoImageToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :logo_image, :string
  end
end
