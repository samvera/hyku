class UpdateFeaturedWorkDefault < ActiveRecord::Migration[5.2]
  def change
    change_column :featured_works, :order, :integer, default: 6
  end
end
