class AddThemesToSites < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :home_theme, :string
    add_column :sites, :show_theme, :string
    add_column :sites, :search_theme, :string
  end
end
