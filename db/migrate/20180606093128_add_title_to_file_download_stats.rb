class AddTitleToFileDownloadStats < ActiveRecord::Migration[5.1]
  def change
    add_column :file_download_stats, :title, :string
  end
end
