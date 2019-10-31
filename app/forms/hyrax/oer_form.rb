# Generated via
#  `rails generate hyrax:work Oer`
module Hyrax
  # Generated form for Oer
  class OerForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    self.model_class = ::Oer
    include HydraEditor::Form::Permissions
    
    self.terms += %i[resource_type rendering_ids alternative_title date table_of_contents 
      additional_information rights_holder oer_size accessibility_feature accessibility_hazard 
      accessibility_summary audience education_level learning_resource_type previous_version]
    self.terms -=%i[keyword based_near related_url source date_created previous_version]    
    self.required_fields += %i[resource_type date audience education_level learning_resource_type]

    def secondary_terms
      super - [:rendering_ids]
    end

  end
end
