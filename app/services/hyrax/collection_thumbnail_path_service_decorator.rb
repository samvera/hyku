# frozen_string_literal: true

module Hyrax
  module CollectionThumbnailPathServiceDecorator
    def default_image
      Site.instance.default_collection_image&.url.presence || super
    end
  end
end

Hyrax::CollectionThumbnailPathService.singleton_class.send(:prepend, Hyrax::CollectionThumbnailPathServiceDecorator)
