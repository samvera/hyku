# frozen_string_literal: true

# TODO: Make more dynamic. Possibly move to Bulkrax. 

module Wings
  module CustomQueries
    class FindBySourceIdentifier
      # Custom query override specific to Wings
      # Use:
      #   Hyrax.custom_queries.find_bulkrax_id(identifier: identifier, models: [ModelClass])

      def self.queries
        [:find_by_source_identifier]
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service

      def initialize(query_service:)
        @query_service = query_service
      end

      def find_by_source_identifier(identifier:, use_valkyrie: true)
        af_object = ActiveFedora::Base.where("bulkrax_identifier_sim:#{identifier}").first

        return af_object unless use_valkyrie

        resource_factory.to_resource(object: af_object)
      end
    end
  end
end