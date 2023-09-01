# Generated via
#  `rails generate hyrax:work Thesis`
module Hyrax
  # Generated form for Thesis
  class ThesisForm < Hyrax::Forms::WorkForm
    self.model_class = ::Thesis
    self.terms += [:resource_type, :contact_email, :contact_phone, :department]
    self.required_fields += [:department, :contact_email]
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
# 
# DEFAULT FORM FIELD BEHAVIOR
# By adding the property to self.terms, it will be added to the new/edit form.
# Without additional customization, the field will be a text input field.
# For contact_email and department, because we did NOT set multiple: true in the
# model, there will be only a single value set for this property.
# For contact_phone, because we DID set multiple: true in the model, there will
# be an `Add another` link below these fields allowing for multiple values to be
# set.
# Because we added contact_email to the required_fields set, it will be
# displayed as required on the initial display of metadata fields on the form.
# Because we did NOT add contact_phone and department to the required_fields
# set, they will only display in the form when you click the `Additional Fields`
# button.
# 
# EXERCISE 2: confirm your changes by running the server and viewing the new/edit
# forms of the Thesis work type. Note that other work types do not have these
# properties.
# 
# EXERCISE 3: Customize the controlled vocabulary field. 
# Now that you see we have a department field in the form, we want to connect it 
# to the controlled vocabulary and enable autocomplete. Finally, create a
# new work to confirm that the autocomplete works. 
# ref: 
# https://gist.github.com/ShanaLMoore/df8562ab13f15ab3a7cc347d61431944#customizing-the-form-field
# 
# If you are attaching a file, be sure sidekiq (or the worker container)
# is running. You can vist the sidekiq dashboard at http://hyku.test/sidekiq to
# watch the jobs process.
# 
# To DISABLE requiring a file, uncomment and set the following config to false: 
# https://github.com/samvera/hyku/blob/main/config/initializers/hyrax.rb#L101
# 
# NOTE: When the work is saved, you will be redirected to the show page. Notice
# that the new properties are not displayed. This is default behavior. 
#
# BONUS EXERCISE: SOLR DASHBOARD
# If you are curious about the data being indexed in Solr, you can visit
# the Solr dashboard at http://solr.hyku.test and run queries.
# The login credentials are in the docker-compose and .env files.
#
# Even though the data is not displayable, you should see the values were saved
# by clicking edit, visiting the solr dashboard, or finding the record in the
# rails console.
# Assuming you've created only 1 Thesis record at this point,
# consider using the following commands from your docker shell:
# `bundle exec rails c`
# `switch!(:tenant)`
# `thesis = Thesis.first`
# `thesis.contact_email`
# `thesis.contact_phone`
# `thesis.department`