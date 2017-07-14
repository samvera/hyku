class IIIFCollectionThumbnailPathService < Hyrax::CollectionThumbnailPathService
  include IIIFThumbnailPaths

  # The image to use if no thumbnail has been selected
  def self.default_image
    ActionController::Base.helpers.image_path 'collection.png'
  end
end
