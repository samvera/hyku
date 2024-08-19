# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work GenericWork`
module Hyrax
  class GenericWorkForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    self.model_class = ::GenericWork
    include HydraEditor::Form::Permissions
    include PdfFormBehavior
    include VideoEmbedFormBehavior

    self.terms += %i[resource_type bibliographic_citation]
  end
end
