# Generated via
#  `rails generate hyrax:work Etd`
module Hyrax
  class EtdPresenter < Hyku::WorkShowPresenter
    delegate :format,
             :degree_name,
             :degree_level,
             :degree_discipline,
             :degree_grantor,
             :advisor,
             :committee_member,
             :department,
             to: :solr_document
  end
end
