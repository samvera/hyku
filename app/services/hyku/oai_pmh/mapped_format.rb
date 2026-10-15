# frozen_string_literal: true

module Hyku
  module OaiPmh
    ##
    # Switches an OAI-PMH metadata format built from a mappings key on and off per tenant.
    # Oai::Provider::BaseDecorator hides any format whose #available? is false.
    #
    # The including format defines +feature+ (its Flipflop feature) and +mapping_key+.
    module MappedFormat
      # A flexible metadata profile opts in by mapping at least one property under the key
      def available?
        return false unless Flipflop.enabled?(feature)
        return true unless Hyrax.config.flexible?

        Hyrax::FlexibleSchema.mappings_data_for(mapping_key).present?
      end
    end
  end
end
