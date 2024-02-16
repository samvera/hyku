# frozen_string_literal: true

class AdminSetResourceForm < Hyrax::Forms::AdministrativeSetForm
  include CollectionAccessFiltering
end