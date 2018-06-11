module Hyrax
  module DownloadsControllerDecorator
    # `asset` is inherited from hydra-head/hydra-core/app/controllers/concerns/hydra/controller/download_behavior.rb
    def send_content
      super
      update_download_stats(asset)
    end

    def download_stats(current_file)
      stat = FileDownloadStat.find_by(file_id: current_file.id)
      return stat if stat
      depositor_id = ::User.find_by(email: current_file.depositor).id
      ## Get the `owner` id instead?? Update FileDownloadStat user_id if change of ownership??
      work_title = current_file.parent.title.first
      ## A Work title can be edited --> TO DO: update FileDownloadStat if title changes
      FileDownloadStat.create(file_id: current_file.id, downloads: 0, title: work_title,
                              user_id: depositor_id, date: [Time.now.utc])
    end

    def update_download_stats(f)
      stats = download_stats(f)
      total = stats.downloads + 1
      dates_arr = stats.date << Time.now.utc
      stats.update_attributes(downloads: total,
                              date: dates_arr) ## rewrites the array in db, could be made more efficient?
    end
  end
end
