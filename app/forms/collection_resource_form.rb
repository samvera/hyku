# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResourceForm < Hyrax::Forms::PcdmCollectionForm
  include Hyrax::FormFields(:basic_metadata) unless Hyrax.config.flexible?
  include Hyrax::FormFields(:bulkrax_metadata) unless Hyrax.config.flexible?
  include Hyrax::FormFields(:collection_resource) unless Hyrax.config.flexible?
  include CollectionAccessFiltering

  # Add hide_from_catalog_search checkbox as a Reform property that will set the property as true or false
  property :hide_from_catalog_search, type: Dry::Types['params.bool'], default: false
end
