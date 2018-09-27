module Hyrax
  class WorkThumbnailPathService < Hyrax::ThumbnailPathService
    class << self
      def default_image
        Site.instance.default_work_image
      end
    end
  end
end