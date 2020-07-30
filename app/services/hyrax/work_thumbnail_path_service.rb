# frozen_string_literal: true

module Hyrax
  class WorkThumbnailPathService < Hyrax::ThumbnailPathService
    class << self
      def default_image
        Site.instance.default_work_image.presence || ActionController::Base.helpers.image_path('work.png')
      end
    end
  end
end
