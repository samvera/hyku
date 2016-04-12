class AddInstitutionNameToSite < ActiveRecord::Migration
  def change
    add_column :sites, :institution_name, :string
  end
end
