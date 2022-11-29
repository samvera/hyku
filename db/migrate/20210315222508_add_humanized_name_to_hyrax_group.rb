class AddHumanizedNameToHyraxGroup < ActiveRecord::Migration[5.2]
  def change
    add_column :hyrax_groups, :humanized_name, :string
  end
end
