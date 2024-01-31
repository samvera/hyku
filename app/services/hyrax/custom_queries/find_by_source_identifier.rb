# frozen_string_literal: true

module Hyrax
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindBySourceIdentifier
      def self.queries
        [:find_by_source_identifier]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service
      delegate :orm_class, to: :resource_factory

      ##
      # @param identifier String
      def find_by_source_identifier(work_identifier:, source_identifier_value:)
        sql_query = sql_by_source_identifier
        query_service.run_query(sql_query, work_identifier, source_identifier_value).first
      end

      def sql_by_source_identifier
        <<-SQL
          SELECT * FROM orm_resources
          WHERE metadata -> ? ->> 0 = ?;
        SQL
      end
    end
  end
end
