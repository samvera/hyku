# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResourceForm < Hyrax::Forms::PcdmCollectionForm
  include Hyrax::FormFields(:basic_metadata)
  include Hyrax::FormFields(:bulkrax_metadata)
  include Hyrax::FormFields(:collection_resource)
  include CollectionAccessFiltering
end
