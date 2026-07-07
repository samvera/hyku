# frozen_string_literal: true

module Hyku
  module DepositWizard
    # Server-side wizard state, backed by a namespaced session hash. The wizard
    # is a sequence of GET-per-step pages, so choices made on one step are
    # persisted here and read back on the next.
    class State
      # Entry paths chosen on the start screen.
      PATHS = %w[new add standalone].freeze

      def initialize(store)
        @store = store || {}
      end

      def path
        @store['path']
      end

      def path=(value)
        @store['path'] = value if PATHS.include?(value)
      end

      def work_type
        @store['work_type']
      end

      def work_type=(value)
        @store['work_type'] = value.presence
      end

      # The raw hash, for assignment back into the session.
      def to_h
        @store
      end
    end
  end
end
