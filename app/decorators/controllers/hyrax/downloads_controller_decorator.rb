module Hyrax
  module DownloadsControllerDecorator
    # `asset` is inherited from hydra-head/hydra-core/app/controllers/concerns/hydra/controller/download_behavior.rb
    def send_content
      super
      WorkDownloadStat.new.log_download(asset)
    end
  end
end
