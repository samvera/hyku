# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0rc2 to make collection thumbnails uploadable

module Hyrax
  module IndexesThumbnailsDecorator
    # Returns the value for the thumbnail path to put into the solr document
    def thumbnail_path
      if object.try(:collection?) && UploadedCollectionThumbnailPathService.uploaded_thumbnail?(object)
        UploadedCollectionThumbnailPathService.call(object)
      else
        super
      end
    end
  end
end

Hyrax::IndexesThumbnails.prepend(Hyrax::IndexesThumbnailsDecorator)
