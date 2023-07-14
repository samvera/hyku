# Generated via
#  `rails generate hyrax:work Thesis`
module Hyrax
  # Generated form for Thesis
  class ThesisForm < Hyrax::Forms::WorkForm
    self.model_class = ::Thesis
    self.terms += [:resource_type]
    self.terms += [:resource_type, :contact_email, :contact_phone, :department]
    self.required_fields += [:department, :contact_email]
  end
end
