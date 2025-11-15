# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to avoid incorrect default connection. Because of the way
# Hyku uses SolrEndpoint, the configuration isn't always appropriate. At times,
# it falls back into the Valkyrie IndexingAdapter instead of Hyrax's, and
# loses the connection.
# TODO: create and initialize a Hyku version of the indexing adapter
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
          @connection = ::SolrEndpoint.new.connection
        end

        def add_documents(*args)
          self.connection = default_connection
          super(*args)
        end
      end
    end
  end
end

Valkyrie::Indexing::Solr::IndexingAdapter.prepend(Valkyrie::Indexing::Solr::IndexingAdapterDecorator)
