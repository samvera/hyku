# frozen_string_literal: true

module Hyrax
  class CollectionThumbnailPathService < Hyrax::ThumbnailPathService
    class << self
      def default_image
        Site.instance.default_collection_image.present? ? Site.instance.default_collection_image.url : ActionController::Base.helpers.image_path('collection.png')
      end
    end
  end
end
