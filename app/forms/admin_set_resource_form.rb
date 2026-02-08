# frozen_string_literal: true

Hyrax::Forms::AdministrativeSetForm.include CollectionAccessFiltering
class AdminSetResourceForm < Hyrax::Forms::AdministrativeSetForm
  check_if_flexible(AdminSetResource)
end
