class CreateAccountCrossSearches < ActiveRecord::Migration[5.2]
  def change
    create_table :account_cross_searches do |t|
      t.references :search_account, foreign_key: { to_table: :accounts }
      t.references :full_account, foreign_key: { to_table: :accounts }

      t.timestamps
    end
  end
end
