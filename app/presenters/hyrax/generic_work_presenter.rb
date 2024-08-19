# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work GenericWork`
module Hyrax
  class GenericWorkPresenter < Hyku::WorkShowPresenter
    delegate :abstract, to: :solr_document
  end
end
