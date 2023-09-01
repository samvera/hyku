# Generated via
#  `rails generate hyrax:work Thesis`
module Hyrax
  # Generated controller for Thesis
  class ThesesController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::Thesis

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::ThesisPresenter
  end
end

# MODEL CLASS
# The model class, which is part of the standard Rails 
# Model-View-Controller, has its name determined by Rails convention.
# self.curation_concern_type == the model name
# model_name = singular controller_name minus 'Controller' (e.g. ::Thesis)
# notice the controller name is plural by Rails convention.
# controller_name = plural model_name plus 'Controller' (e.g. Theses)
#
# FORM CLASS
# The form class is used to control how metadata appears on the new/edit work
# form. A form class is created for each work type when the work type is
# generated. The controller knows about this class through the
# work_form_service.rb form_class method.
# ref:
# https://github.com/samvera/hyrax/blob/main/app/services/hyrax/work_form_service.rb
# Default: form_class = model_name.name + Form (e.g. ThesisWorkForm)
# Modifying: Although uncommon, you can change the class that is used as the
# form class by setting it in the controller 
# ie: self.form_class = MyCustomForm
#
# PRESENTER CLASS
# The presenter class is used to control how metadata appears on the work show
# page. This is automatically generated and it inherits from
# Hyrax::WorkShowPresenter
# Modifying: You can change the class that is used as the presenter class by
# setting it in the controller.
# ie: self.show_presenter = MyCustomPresenter