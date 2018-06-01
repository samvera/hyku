module Hyrax
  Admin::StatsController.class_eval do
    def show
      super
      @works_to_display ||= ::FileDownloadStat.all.select do |e|
        e[:user_id] == current_user.id
      end
      @total_downloads ||= @works_to_display.map(&:downloads).reduce(:+)
    end
  end
end
