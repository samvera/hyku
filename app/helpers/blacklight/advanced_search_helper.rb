# frozen_string_literal: true

module Blacklight
  # Helpers related to the advanced search functionality of Blacklight.
  module AdvancedSearchHelper
    # Retrieves the first six search fields from a given collection.
    #
    # @param fields [Array] collection of search fields
    # @return [Array] a subset of the input collection containing the first six fields
    def primary_search_fields_for(fields)
      fields.each_with_index.partition { |_, idx| idx < 6 }.first.map(&:first)
    end

    # Retrieves all search fields from a given collection except the first six.
    #
    # @param fields [Array] collection of search fields
    # @return [Array] a subset of the input collection excluding the first six fields
    def secondary_search_fields_for(fields)
      fields.each_with_index.partition { |_, idx| idx < 6 }.last.map(&:first)
    end

    # Determines if the provided key represents a local authority.
    #
    # @param key [String] the key to be checked
    # @return [Boolean] true if the key or its pluralized form is found in the local authorities list; false otherwise
    def local_authority?(key)
      local_qa_names = Qa::Authorities::Local.names
      local_qa_names.include?(key.pluralize) || local_qa_names.include?(key)
    end

    # Gets the options for a QA select based on a given key.
    #
    # @param key [String] the key used to fetch the service and retrieve options
    # @return [Array, nil] the options available for the select, or nil if the service does not provide any options
    def options_for_qa_select(key)
      service = fetch_service_for(key)
      service.try(:select_all_options) || service.try(:select_options) || service.new.select_all_options
    end

    private

      # Fetches the service for a given key.
      #
      # @param key [String] the key used to determine the service name
      # @return [Class, nil] the service class based on the key, or nil if it does not exist
      def fetch_service_for(key)
        "Hyrax::#{key.camelize}Service".safe_constantize || "Hyrax::#{key.pluralize.camelize}Service".safe_constantize
      end
  end
end
