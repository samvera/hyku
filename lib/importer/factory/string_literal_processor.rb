# frozen_string_literal: true

module Importer
  module Factory
    # Transform the attributes from the parser into basic string literals.
    # An alternative processor may choose to find or create linked entities
    class StringLiteralProcessor
      # @param [Hash] attributes the input from the parser
      # @return [Hash] a duplicate with the structured data converted to literals
      # @example:
      #   process(contributor: [{ name: ["Muybridge"], type: "corporate" }])
      #   # => { contributor: ["Muybridge"] }
      def self.process(attributes)
        attributes.merge(contributors(attributes))
      end

      # @param [Hash] attributes input data
      # @return [Hash] transformed contributor data
      def self.contributors(attributes)
        value = attributes[:contributor]
        return {} unless value
        { contributor: value.map { |c| c[:name].join(' — ') } }
      end
    end
  end
end
