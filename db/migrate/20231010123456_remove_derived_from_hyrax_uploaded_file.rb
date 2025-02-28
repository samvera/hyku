class RemoveDerivedFromHyraxUploadedFile < ActiveRecord::Migration[5.2]
  def change
    if column_exists?(:uploaded_files, :derived)
      remove_column :uploaded_files, :derived
    end
  end
end 