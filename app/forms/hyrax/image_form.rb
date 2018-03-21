# Generated via
#  `rails generate hyrax:work Image`
module Hyrax
  class ImageForm < Hyrax::Forms::WorkForm
    self.model_class = ::Image
    self.terms += %i[resource_type extent rendering_ids]

    def secondary_terms
      super - [:rendering_ids]
    end
  end
end
