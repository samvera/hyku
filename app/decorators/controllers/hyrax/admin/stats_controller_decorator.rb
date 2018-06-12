module Hyrax
  Admin::StatsController.class_eval do
    def show
      super
      @works_to_display ||= ::WorkDownloadStat.where(owner_id: current_user.id)
      @total_downloads = @works_to_display.map(&:downloads).reduce(:+)
    end
  end
end
