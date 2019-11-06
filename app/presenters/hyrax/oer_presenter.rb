# Generated via
#  `rails generate hyrax:work Oer`
module Hyrax
  class OerPresenter < Hyku::WorkShowPresenter
    delegate :alternative_title, :date, :table_of_contents, :additional_information,
             :rights_holder, :oer_size, :accessibility_feature, :accessibility_hazard,
             :accessibility_summary, :audience, :education_level, :learning_resource_type, 
             :discipline, :previous_version, to: :solr_document
  end
end
