# frozen_string_literal: true

# Override Hyrax v5.0 to avoid incorrect default connection
# TODO: create and initialize a Hyku version of the indexing adapter
module Valkyrie
  module Indexing
    module Solr
      module IndexingAdapterDecorator
        def default_connection
          ::SolrEndpoint.new.connection
        end
      end
    end
  end
end

Valkyrie::Indexing::Solr::IndexingAdapter.prepend(Valkyrie::Indexing::Solr::IndexingAdapterDecorator)
