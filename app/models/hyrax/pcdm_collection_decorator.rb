# OVERRIDE Hyrax 5.0 to add basic metadata and AF methods to collection

Hyrax::PcdmCollection.class_eval do
  include Hyrax::Schema(:basic_metadata)
  include Hyrax::ArResource
end
