class WorkDownloadStat < ApplicationRecord
  def current_work_stats(work)
    WorkDownloadStat.find_or_create_by(work_uid: work.parent.id) do |wds|
      wds.title = work.parent.title.first
      wds.owner_id = ::User.find_by(email: work.depositor).id
    end
  end

  def log_download(record)
    stats = current_work_stats(record)
    total = stats.downloads + 1
    dates_arr = stats.date << Time.now.utc
    stats.update_attributes(downloads: total,
                            date: dates_arr) ## rewrites the array in db, could be made more efficient?
  end
end
