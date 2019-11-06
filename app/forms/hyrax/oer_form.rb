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
      accessibility_summary audience education_level learning_resource_type discipline previous_version]
    self.terms -=%i[keyword based_near related_url source date_created previous_version]    
    self.required_fields += %i[resource_type date audience education_level learning_resource_type discipline]

    delegate :related_members_attributes=, to: :model

    def secondary_terms
      super - [:rendering_ids]
    end

    def self.build_permitted_params
      super + [
        {
          related_members_attributes: [:id, :_destroy]
        }
      ]
    end
  end
end
