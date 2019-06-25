module Hyrax
  class WorkThumbnailPathService < Hyrax::ThumbnailPathService
    class << self
      def default_image
        Site.instance.default_work_image.present? ? Site.instance.default_work_image : ActionController::Base.helpers.image_path('work.png')
      end
    end
  end
end
