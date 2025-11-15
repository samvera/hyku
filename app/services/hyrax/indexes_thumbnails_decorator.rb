# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to make collection thumbnails uploadable

module Hyrax
  module IndexesThumbnailsDecorator
    # Returns the value for the thumbnail path to put into the solr document
    def thumbnail_path
      object ||= @object || resource
      file_path = CollectionResourceIndexer.thumbnail_path_service.call(object)
      if object.try(:collection?) && UploadedCollectionThumbnailPathService.uploaded_thumbnail?(object)
        UploadedCollectionThumbnailPathService.call(object)
      elsif file_path&.include?('/branding')
        file_path.gsub(/.*?(\/branding)/, '\1')
      else
        file_path
      end
    end
  end
end

Hyrax::IndexesThumbnails.prepend(Hyrax::IndexesThumbnailsDecorator)
