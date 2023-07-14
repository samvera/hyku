# Generated via
#  `rails generate hyrax:work Thesis`
module Hyrax
  class ThesisPresenter < Hyrax::WorkShowPresenter
    delegate :contact_email, :contact_phone, :department, to: :solr_document
  end
end
