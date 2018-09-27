# frozen_string_literal: true

module Hyrax
  class CollectionThumbnailPathService < Hyrax::ThumbnailPathService
    class << self
      def default_image
        Site.instance.default_collection_image
      end
    end
  end
end