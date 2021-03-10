# Generated via
#  `rails generate hyrax:work Etd`
module Hyrax
  # Generated form for Etd
  class EtdForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    self.model_class = ::Etd
    include HydraEditor::Form::Permissions

    self.terms += [
      :resource_type,
      :format,
      :degree_name,
      :degree_level,
      :degree_discipline,
      :degree_grantor,
      :advisor,
      :committee_member,
      :department
    ]

    self.terms -= [:based_near]

    self.required_fields = [
      :title,
      :creator,
      :rights_statement,
      :date_created,
      :degree_name,
      :degree_level,
      :degree_discipline,
      :degree_grantor
    ]
  end
end
