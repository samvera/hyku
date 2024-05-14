# frozen_string_literal: true

# Require the necessary file at the beginning
require 'hyrax/transactions/transaction'

# OVERRIDE Hyrax v5.0.0 to add the ability to upload a collection thumbnail
module Hyrax
  module Transactions
    # Use class_eval to reopen the class for modification
    CollectionUpdate.class_eval do
      # Override the initialize method to alter the default steps
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
