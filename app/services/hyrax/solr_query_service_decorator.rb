# OVERRIDE: Hyrax 5.2.0 changes GET request to POST to allow for larger query size

# frozen_string_literal: true

module Hyrax
  module SolrQueryServiceDecorator
    def get(*args)
      solr_service.post(build, *args)
    end
  end
end

Hyrax::SolrQueryService.prepend(Hyrax::SolrQueryServiceDecorator)
