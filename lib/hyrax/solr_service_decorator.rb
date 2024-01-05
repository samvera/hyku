# frozen_string_literal: true

# OVERRIDE: class Hyrax::SolrService from Hyrax 5.0
module Hyrax
  module SolrServiceDecorator
    # Get the count of records that match the query
    # @param [String] query a solr query
    # @param [Hash] args arguments to pass through to `args' param of SolrService.query
    # (note that :rows will be overwritten to 0)
    # @return [Integer] number of records matching
    #
    # OVERRIDE: use `post` rather than `get` to handle larger query sizes
    def count(query, args = {})
      args = args.merge({ rows: 0, method: :post })
      query_result(query, **args)['response']['numFound'].to_i
    end

    # TODO: does Valkyrie Solr Service need to be reset in some way?
    def reset!
      @old_service.reset! if @old_service
      valkyrie_index.connection = valkyrie_index.default_connection
    end
  end
end

Hyrax::SolrService.singleton_class.send(:prepend, Hyrax::SolrServiceDecorator)
