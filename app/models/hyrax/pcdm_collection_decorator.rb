# OVERRIDE Hyrax 5.0 to add basic metadata and AF methods to collection

Hyrax::PcdmCollection.class_eval do
  include Hyrax::Schema(:basic_metadata)
  include Hyrax::ArResource
  prepend OrderAlready.for(:creator)

  ## TODO: Custom behavior to make functional
  # after_update :remove_featured, if: proc { |collection| collection.private? }
  # after_destroy :remove_featured

  # def remove_featured
  #   FeaturedCollection.where(collection_id: id).destroy_all
  # end
end
