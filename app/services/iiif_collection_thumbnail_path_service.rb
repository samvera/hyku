class IIIFCollectionThumbnailPathService < Hyrax::CollectionThumbnailPathService
  include IIIFThumbnailPaths

  # The image to use if no thumbnail has been selected
  def self.default_image
    Site.instance.default_collection_image
  end
end
