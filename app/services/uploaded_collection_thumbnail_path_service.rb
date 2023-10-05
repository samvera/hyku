# frozen_string_literal: true

class UploadedCollectionThumbnailPathService < Hyrax::ThumbnailPathService
  class << self
    # @param [Collection] object to get the thumbnail path for an uploaded image
    def call(object)
      "/uploads/uploaded_collection_thumbnails/#{object.id}/#{object.id}_card.jpg"
    end

    # rubocop:disable Metrics/LineLength, Rails/FilePath, Lint/StringConversionInInterpolation
    def uploaded_thumbnail?(collection)
      File.exist?(File.join(upload_dir(collection), "#{collection.id}_card.jpg"))
    end

    def upload_dir(collection)
      Hyku::Application.path_for("public/uploads/uploaded_collection_thumbnails/#{collection.id}")
    end
    # rubocop:enable Metrics/LineLength, Rails/FilePath, Lint/StringConversionInInterpolation
  end
end
