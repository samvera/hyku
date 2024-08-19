# frozen_string_literal: true
# Generated via
#  `rails generate hyrax:work Etd`
module Hyrax
  # Generated form for Etd
  class EtdForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    self.model_class = ::Etd
    include HydraEditor::Form::Permissions
    include PdfFormBehavior
    include VideoEmbedFormBehavior

    self.terms = [:admin_note] + self.terms # rubocop:disable Style/RedundantSelf
    self.terms += [
      :resource_type,
      :format,
      :degree_name,
      :degree_level,
      :degree_discipline,
      :degree_grantor,
      :advisor,
      :committee_member,
      :department,
      :creator,
      :additional_information,
      :bibliographic_citation
    ]

    self.required_fields = [
      :title,
      :creator,
      :keyword,
      :rights_statement,
      :date_created,
      :degree_name,
      :degree_level,
      :degree_discipline,
      :degree_grantor,
      :resource_type
    ]
  end
end
