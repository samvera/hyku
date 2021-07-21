# Generated via
#  `rails generate hyrax:work Oer`
module Hyrax
  # Generated controller for Oer
  class OersController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::Oer

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::OerPresenter
  end
end
