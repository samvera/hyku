# OVERRIDE: Hyrax 5.2.0 changes GET request to POST to allow for larger query size

# frozen_string_literal: true

module Hyrax
  module SolrQueryServiceDecorator
    def get(*args)
      solr_service.post(build, *args)
    end
  end
end

# Defer the prepend so that autoloading Hyrax::SolrQueryService (whose class
# body calls Hyrax.query_service) happens after the metadata adapter is fully
# configured in the after_initialize block.
Rails.application.config.after_initialize do
  Hyrax::SolrQueryService.prepend(Hyrax::SolrQueryServiceDecorator)
end
