# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to give the file set form the bulkrax_identifier field that Hyrax::FileSetDecorator adds to the model
module Hyrax
  module Forms
    module FileSetFormDecorator
      extend ActiveSupport::Concern

      prepended do
        unless Hyrax.config.flexible?
          include Hyrax::FormFields(:bulkrax_metadata) if Hyrax.config.file_set_include_metadata?
        end
      end
    end
  end
end

Hyrax::Forms::FileSetForm.prepend Hyrax::Forms::FileSetFormDecorator
