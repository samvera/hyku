# Generated via
#  `rails generate hyrax:work Oer`
module Hyrax
  # Generated form for Oer
  class OerForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    self.model_class = ::Oer
    include HydraEditor::Form::Permissions
    self.terms += %i[resource_type rendering_ids]
    
    def secondary_terms
      super - [:rendering_ids]
    end

  end
end
