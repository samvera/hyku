class CreateHyraxFlexibleSchemas < ActiveRecord::Migration[6.1]
  def change
    unless table_exists?(:hyrax_flexible_schemas)
      create_table :hyrax_flexible_schemas do |t|
        t.text :profile

        t.timestamps
      end
    end
  end
end
