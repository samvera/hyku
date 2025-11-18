# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResourceForm < Hyrax::Forms::PcdmCollectionForm
  if Hyrax.config.collection_include_metadata?
    include Hyrax::FormFields(:basic_metadata)
    include Hyrax::FormFields(:bulkrax_metadata)
    include Hyrax::FormFields(:collection_resource)
  end
  check_if_flexible(CollectionResource)

  include CollectionAccessFiltering

  # Add hide_from_catalog_search checkbox as a Reform property that will set the property as true or false
  unless Hyrax.config.collection_flexible?
    property :hide_from_catalog_search, type: Dry::Types['params.bool'], default: false if CollectionResource.new.respond_to?(:hide_from_catalog_search)
  end
end
