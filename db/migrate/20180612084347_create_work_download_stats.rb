class CreateWorkDownloadStats < ActiveRecord::Migration[5.1]
  def change
    create_table :work_download_stats do |t|
      t.string :work_uid
      t.string :title
      t.integer :downloads
      t.integer :owner_id
      t.datetime :date, array: true, default: []

      t.timestamps null: false
    end

    add_index :work_download_stats, :owner_id
    add_index :work_download_stats, :work_uid
  end
end
