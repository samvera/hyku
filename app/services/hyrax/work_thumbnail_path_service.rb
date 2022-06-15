# frozen_string_literal: true

# OVERRIDE Hyrax 3.4.0 use site defaults over app default
module Hyrax
  class WorkThumbnailPathService < Hyrax::ThumbnailPathService
    class << self
      def default_image
        Site.instance.default_work_image&.url || ActionController::Base.helpers.image_path('work.png')
      end
    end
  end
end
