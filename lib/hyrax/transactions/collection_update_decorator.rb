# frozen_string_literal: true

# OVERRIDE Hyrax to add a `save_collection_thumbnail` step to the
# CollectionUpdate transaction. Build the step list by inserting into
# upstream's DEFAULT_STEPS rather than hardcoding, so future upstream
# additions (e.g. sync_redirect_paths) are picked up automatically.

module Hyrax
  module Transactions
    module CollectionUpdateDecorator
      default_steps = Hyrax::Transactions::CollectionUpdate::DEFAULT_STEPS.dup
      logo_index = default_steps.index('collection_resource.save_collection_logo')
      DEFAULT_STEPS = default_steps.insert(logo_index + 1, 'collection_resource.save_collection_thumbnail').freeze

      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end

Hyrax::Transactions::CollectionUpdate.prepend(Hyrax::Transactions::CollectionUpdateDecorator)
