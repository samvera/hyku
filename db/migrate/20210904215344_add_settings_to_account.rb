class AddSettingsToAccount < ActiveRecord::Migration[5.2]
  def change
    unless column_exists?(:accounts, :settings)
      add_column :accounts, :settings, :jsonb, default: {}
      add_index  :accounts, :settings, using: :gin
    end
  end
end
