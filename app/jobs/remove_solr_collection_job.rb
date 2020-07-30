# frozen_string_literal: true

class RemoveSolrCollectionJob < ApplicationJob
  # @param collection [String] the name of the collection
  # @param connection_options [Hash] options for connecting to solr.
  # @option connection_options [String] :url
  # @option connection_options [String] :url
  def perform(collection, connection_options)
    solr_client(connection_options).get '/solr/admin/collections', params: { action: 'DELETE', name: collection }
  end

  private

    def solr_client(connection_options)
      # We remove the adapter, otherwise RSolr 2 will try to use it as a Faraday middleware
      RSolr.connect(connection_options.without('adapter'))
    end
end
