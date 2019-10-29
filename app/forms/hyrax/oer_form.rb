# Generated via
#  `rails generate hyrax:work Oer`
module Hyrax
  # Generated form for Oer
  class OerForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    self.model_class = ::Oer
    include HydraEditor::Form::Permissions
    
    self.terms += %i[resource_type rendering_ids alternative_title date table_of_contents additional_information rights_holder oer_size accessibility_feature accessibility_hazard accessibility_summary]
    self.terms -=%i[keyword based_near related_url source date_created]    
    self.required_fields += %i[date]

    def secondary_terms
      super - [:rendering_ids]
    end

  end
end
