class AddAvailableWorksToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :available_works, :text, array: true, default: []
  end
end