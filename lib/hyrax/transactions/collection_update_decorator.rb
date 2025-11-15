# frozen_string_literal: true

module Hyrax
  module Transactions
    # Decorator module to override CollectionUpdate behavior
    module CollectionUpdateDecorator
      def initialize(container: Container, steps: nil)
        # Define the new steps array including the new thumbnail step
        new_steps = ['change_set.apply',
                     'collection_resource.save_collection_banner',
                     'collection_resource.save_collection_logo',
                     'collection_resource.save_collection_thumbnail',
                     'collection_resource.save_acl'].freeze

        # Use the new steps array if steps argument is nil, else use provided steps
        super(container:, steps: steps || new_steps)
      end
    end
  end
end

# Prepend the decorator to the CollectionUpdate class
Hyrax::Transactions::CollectionUpdate.prepend(Hyrax::Transactions::CollectionUpdateDecorator)
