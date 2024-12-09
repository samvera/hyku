class AddContextsToHyraxFlexibleSchemas < ActiveRecord::Migration[6.1]
  def change
    add_column :hyrax_flexible_schemas, :contexts, :text
  end
end
