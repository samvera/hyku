class AddInstitutionNameFullToSite < ActiveRecord::Migration
  def change
    add_column :sites, :institution_name_full, :string
  end
end
