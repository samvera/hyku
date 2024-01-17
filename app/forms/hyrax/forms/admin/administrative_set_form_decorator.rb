# frozen_string_literal: true

module Hyrax
  module Forms
    module AdministrativeSetFormDecorator
      include CollectionAccessFiltering
    end
  end
end

Hyrax::Forms::AdministrativeSetForm.prepend(Hyrax::Forms::AdministrativeSetFormDecorator)
