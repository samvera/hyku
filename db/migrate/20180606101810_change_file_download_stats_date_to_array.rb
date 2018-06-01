class ChangeFileDownloadStatsDateToArray < ActiveRecord::Migration[5.1]
  def change
    remove_column :file_download_stats, :date, :datetime
    add_column :file_download_stats, :date, :datetime, array: true, default: []
  end
end