# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Image`
module Hyrax
  class ImageForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    self.model_class = ::Image
    include PdfFormBehavior
    include VideoEmbedFormBehavior

    self.terms += %i[resource_type extent bibliographic_citation]
  end
end
