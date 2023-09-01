# Generated via
#  `rails generate hyrax:work Thesis`
module Hyrax
  # Generated form for Thesis
  class ThesisForm < Hyrax::Forms::WorkForm
    self.model_class = ::Thesis
    self.terms += [:resource_type]
  end
end

# The inclusion of properties in the new/edit form is controlled by the
# ThesisForm class. The ThesisForm class is generated with the basic
# set of properties (aka terms, aka metadata fields) to include, because
# it inherits from Hyrax::Forms::WorkForm.
# ref: 
# https://github.com/samvera/hyrax/blob/7e313b13ed0a5a49c4c52c495a59aaef9ec96435/app/forms/hyrax/forms/work_form.rb
# NOTABLE WORKFORM METHODS
# ref: 
# https://gist.github.com/ShanaLMoore/df8562ab13f15ab3a7cc347d61431944#notable-workform-methods
# 
# EXERCISE: update ThesisForm terms to include each of the new properties 
# contact_email, contact_phone, department).
# 
# OPTIONALLY, you can ADD properties to the set of required fields.
# In this example, we will require the department and contact email by adding
# the following code to ThesisForm.
#     self.required_fields += [:department, :contact_email]
# 
# OPTIONALLY, you can REMOVE properties to the set of primary fields.
# example: 
#     self.required_fields -= [:keyword, :rights]
