# frozen_string_literal: true

module Hyrax
  class CollectionThumbnailPathService < Hyrax::ThumbnailPathService
    class << self
      def default_image
        hyrax_default_collection_image = ActionController::Base.helpers.image_path('collection.png')

        Site.instance.default_collection_image&.url.presence || hyrax_default_collection_image
      end
    end
  end
end
