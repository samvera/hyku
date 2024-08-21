class CreateUserBatchEmails < ActiveRecord::Migration[6.1]
  def change
    create_table :user_batch_emails do |t|
      t.references :user, unique: true, index: true
      t.datetime :last_emailed_at

      t.timestamps
    end
  end
end
