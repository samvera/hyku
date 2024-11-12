# frozen_string_literal: true

module Bulkrax
  module ApplicationParserDecorator
    # OVERRIDE: [Bulkrax v8.3.0] Use the current Account's configured :bulkrax_split_pattern
    # setting as the default split pattern when importing multi-valued fields
    def multi_value_element_split_on
      Regexp.new(Site.account&.settings&.dig('bulkrax_split_pattern')) || super
    end
  end
end

Bulkrax::ApplicationParser.singleton_class.send(:prepend, Bulkrax::ApplicationParserDecorator)
