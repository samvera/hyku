class AddDefaultWorkTypeToSites < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :default_work_type, :string
  end
end
