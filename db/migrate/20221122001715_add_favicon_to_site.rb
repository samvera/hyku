class AddFaviconToSite < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :favicon, :string
  end
end
