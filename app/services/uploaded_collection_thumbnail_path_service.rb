# frozen_string_literal: true

class UploadedCollectionThumbnailPathService < Hyrax::ThumbnailPathService
  class << self
    # @param [Collection] object to get the thumbnail path for an uploaded image
    def call(object)
      "/uploads/uploaded_collection_thumbnails/#{object.id}/#{object.id}_card.jpg"
    end

    # rubocop:disable Layout/LineLength
    def uploaded_thumbnail?(collection)
      File.exist?("#{Rails.root}/public/uploads/uploaded_collection_thumbnails/#{collection.id}/#{collection.id}_card.jpg")
    end

    def upload_dir(collection)
      "#{Rails.root}/public/uploads/uploaded_collection_thumbnails/#{collection.id}"
    end
    # rubocop:enable Layout/LineLength
  end
end
