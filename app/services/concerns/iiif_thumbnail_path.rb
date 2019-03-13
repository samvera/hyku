module IIIFThumbnailPaths
  extend ActiveSupport::Concern

  class_methods do
    # @param [FileSet] file_set
    # @param [String] size ('!150,300') an IIIF image size defaults to an image no
    #                      wider than 150px and no taller than 300px
    # @return the IIIF url for the thumbnail if it's an image, otherwise gives
    #         the thumbnail download path
    def thumbnail_path(file_set, size = '!150,300'.freeze)
      return super(file_set) unless file_set.image?
      iiif_thumbnail_path(file_set, size)
    end

    # @private
    def iiif_thumbnail_path(file_set, size)
      file = file_set.original_file
      return unless file
      Riiif::Engine.routes.url_helpers.image_path(
        file.id,
        size: size
      )
    end

    # @param [FileSet] thumbnail the object that is the thumbnail
    # @return [boolean] true when a thumbnail (either generated or a common asset)
    #                   is expected to be available on the file system
    def thumbnail?(thumbnail)
      return true if thumbnail.image? || thumbnail.pdf? || thumbnail.office_document? ||
                     thumbnail.audio? || thumbnail.video?
      super(thumbnail)
    end
  end
end
