class ChangeFeaturesToSufiaFeatures < ActiveRecord::Migration[5.0]
  def change
    rename_table :features, :sufia_features
  end
end
