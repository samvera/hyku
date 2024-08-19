# frozen_string_literal: true
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
             :abstract,
             to: :solr_document

    def human_readable_type
      Etd.model_name.i18n_key.upcase
    end
  end
end
