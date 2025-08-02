# frozen_string_literal: true

##
# A custom query used by IiifPrint to find a resource by its model and title.
# Ideally should be defined in IiifPrint, but currently gem custom queries are registered in
# Hyku's initializer and not available in the gem itself, so we are defining it here.
# There is not an equivalent custom query defined for wings, as IiifPrint did not need it.
module Hyrax
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindByModelAndPropertyValue
      def self.queries
        [:find_by_model_and_property_value]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service
      delegate :orm_class, to: :resource_factory

      ##
      # @param model [Class, #internal_resource]
      # @param property [#to_s] the name of the property we're attempting to
      #        query.
      # @param value [#to_s] the property's value that we're trying to match.
      #
      # @return [NilClass] when no record was found
      # @return [Valkyrie::Resource] when record was found (returns only first value)
      def find_by_model_and_property_value(model:, property:, value:)
        sql_query = sql_for_find_by_model_and_property_value
        query_service.run_query(sql_query, model, property, value).first
      end

      private

      def sql_for_find_by_model_and_property_value
        # NOTE: This is querying the first element of the property, but we might
        # want to check all of the elements.
        <<-SQL
          SELECT * FROM orm_resources
          WHERE internal_resource = ? AND metadata -> ? ->> 0 = ?
          LIMIT 1;
        SQL
      end
    end
  end
end
