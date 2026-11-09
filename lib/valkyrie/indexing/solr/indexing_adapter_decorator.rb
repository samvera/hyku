# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0
#   - build the default connection from Hyku's SolrEndpoint
#   - keep the connection per thread, as ActiveFedora and Blacklight keep theirs
module Valkyrie
  module Indexing
    module Solr
      module IndexingAdapterDecorator
        # OVERRIDE: one adapter serves every thread and tenant, so SolrEndpoint#switch! must set
        # the connection for its own thread only, or deletes go to whichever tenant switched last.
        thread_mattr_accessor :thread_connection

        def connection
          IndexingAdapterDecorator.thread_connection ||= default_connection
        end

        def connection=(connection)
          IndexingAdapterDecorator.thread_connection = connection
        end

        def default_connection
          ::SolrEndpoint.new.connection
        end
      end
    end
  end
end

Valkyrie::Indexing::Solr::IndexingAdapter.prepend(Valkyrie::Indexing::Solr::IndexingAdapterDecorator)
