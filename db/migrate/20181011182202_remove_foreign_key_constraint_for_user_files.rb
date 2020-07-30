class RemoveForeignKeyConstraintForUserFiles < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key :uploaded_files, :users
    remove_foreign_key :curation_concerns_operations, :users
  end
end
