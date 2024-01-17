# # frozen_string_literal: true

Hyrax::Forms::PcdmCollectionForm.class_eval do
  include Hyrax::FormFields(:basic_metadata)
  include CollectionAccessFiltering
end
