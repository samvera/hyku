# Generated via
#  `rails generate hyrax:work Oer`
module Hyrax
  class OerPresenter < Hyku::WorkShowPresenter
    delegate :accessibility_feature, :accessibility_hazard,
      :accessibility_summary, to: :solr_document
  end
end
