class AddBrandingToCollectionType < ActiveRecord::Migration[5.1]
  def change
    add_column :hyrax_collection_types, :brandable, :boolean, null: false, default: true
  end
end
