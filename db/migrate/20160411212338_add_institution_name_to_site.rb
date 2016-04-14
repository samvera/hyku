class AddInstitutionNameToSite < ActiveRecord::Migration
  def change
    add_column :sites, :institution_name, :string
    add_column :sites, :institution_name_full, :string
  end
end
