# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 - index using site defaults instead of app wide defaults

module Hyrax
  module ThumbnailPathServiceDecorator
    def call(object)
      return super unless object.try(:collection?)

      collection_thumbnail = CollectionBrandingInfo.where(collection_id: object.id.to_s, role: "thumbnail").first
      return collection_thumbnail.local_path.gsub(Hyrax.config.branding_path.to_s, '/branding') if collection_thumbnail

      if object.try(:thumbnail_id).blank?
        return default_collection_image if object.try(:collection?)
        return default_image
      end

      thumb = fetch_thumbnail(object)
      return default_collection_image unless thumb

      return call(thumb) unless thumb.file_set?
      if audio?(thumb)
        audio_image
      elsif thumbnail?(thumb)
        thumbnail_path(thumb)
      else
        default_collection_image
      end
    end

    def default_collection_image
      Site.instance.default_collection_image&.url || ActionController::Base.helpers.image_path('default.png')
    end

    def default_image
      Site.instance.default_work_image&.url || super
    end
  end
end

Hyrax::ThumbnailPathService.singleton_class.send(:prepend, Hyrax::ThumbnailPathServiceDecorator)
