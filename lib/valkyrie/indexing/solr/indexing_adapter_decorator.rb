# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0
#   - build the default connection from Hyku's SolrEndpoint
#   - read the connection from the current thread's tenant on every call
module Valkyrie
  module Indexing
    module Solr
      module IndexingAdapterDecorator
        ##
        # @param connection [RSolr::Client] The RSolr connection to index to.
        def initialize(connection: ::SolrEndpoint.new.connection)
          @connection = connection
        end

        def default_connection
          ::SolrEndpoint.new.connection
        end

        # OVERRIDE: one adapter serves every thread and tenant, and SolrEndpoint#switch! sets its
        # connection for whichever tenant switched last, so saves, deletes and wipes each build
        # this thread's own.
        def connection
          ::SolrEndpoint.new.connection
        end
      end
    end
  end
end

Valkyrie::Indexing::Solr::IndexingAdapter.prepend(Valkyrie::Indexing::Solr::IndexingAdapterDecorator)
