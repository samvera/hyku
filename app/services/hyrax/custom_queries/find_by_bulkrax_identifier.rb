# frozen_string_literal: true
module Hyrax
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindByBulkraxIdentifier
      def self.queries
        [:find_by_bulkrax_identifier]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service
      delegate :orm_class, to: :resource_factory

      ##
      # @param identifier String
      def find_by_bulkrax_identifier(identifier:)
        query_service.run_query(sql_by_bulkrax_identifier, identifier).first
      end

      def sql_by_bulkrax_identifier
        <<-SQL
          SELECT * FROM orm_resources
          WHERE metadata -> 'bulkrax_identifier' ->> 0 = ?;
        SQL
      end
    end
  end
end
