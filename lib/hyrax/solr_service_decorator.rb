# frozen_string_literal: true

# OVERRIDE: class Hyrax::SolrService from Hyrax 5.0
module Hyrax
  module SolrServiceDecorator
    extend ActiveSupport::Concern

    class_methods do
      # Follows pattern of delegation to new in the Hyrax::SolrService baseline.
      delegate :reset!, :connection, to: :new
    end

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
      @old_service&.reset!

      Hyrax.index_adapter&.reset!
    end

    # Override Hyrax SolrService connection method to always use Hyku's connection method.
    def connection
      SolrEndpoint.new.connection
    end
  end
end

Hyrax::SolrService.prepend(Hyrax::SolrServiceDecorator)
