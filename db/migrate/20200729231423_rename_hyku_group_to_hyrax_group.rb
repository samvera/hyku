class RenameHykuGroupToHyraxGroup < ActiveRecord::Migration[5.1]
  def change
    rename_table :hyku_groups, :hyrax_groups
  end
end
