# Generated via
#  `rails generate hyrax:work OerWork`
module Hyrax
  # Generated form for OerWork
  class OerWorkForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    self.model_class = ::OerWork
    include HydraEditor::Form::Permissions
    self.terms += %i[resource_type rendering_ids]
    
    def secondary_terms
      super - [:rendering_ids]
    end
  end
end
