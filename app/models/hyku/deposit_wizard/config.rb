# frozen_string_literal: true

module Hyku
  module DepositWizard
    # Configuration seam for the guided deposit wizard. See
    # docs/deposit-wizard.md for the full option reference and insertion points.
    # Downstream apps replace the shared instance via +Hyku::DepositWizard.config+.
    class Config
      # The parent/collection/sharing capabilities are per-tenant Flipflop
      # features, deliberately kept separate from static config: a flag must switch
      # and take effect immediately, so these are read live from Flipflop on every
      # call — never stored on the config, never overridable in memory. (Static
      # deployment settings live on Config itself.)
      module Capabilities
        module_function

        def parent_connect?
          Flipflop.deposit_wizard_parent_connect?
        end

        def collection_connect?
          Flipflop.deposit_wizard_collection_connect?
        end

        def sharing?
          Flipflop.deposit_wizard_sharing?
        end
      end

      attr_accessor :container_type, :item_types, :suggestions,
                    :post_commit, :parent_types, :parent_connect_placement
      attr_writer :flow

      # Only takes effect when parent-connect is enabled.
      # Where the parent-connect capability offers to attach a parent:
      # :review (default — only the review-step section),
      # :start (only the up-front "add to an existing work" path),
      # :both, or
      # :none (offers on neither edge).
      PARENT_CONNECT_PLACEMENTS = %i[both start review none].freeze

      def capabilities
        Capabilities
      end

      def initialize
        @container_type = nil
        @item_types = nil
        @suggestions = {}
        @post_commit = nil
        @parent_types = nil
        @parent_connect_placement = :review
        yield self if block_given?
      end

      def container?
        container_type.present?
      end

      # The ordered wizard step sequence (a Flow). Downstream apps reshape the
      # wizard by assigning their own Flow; defaults to the built-in sequence.
      def flow
        @flow ||= Flow.default
      end

      # item_start is only worth showing when a guided sub-flow is configured (the
      # file→subtype suggestion map); otherwise the flow skips it.
      def item_start_offers_choice?
        suggestions.present?
      end

      # The up-front "add to an existing work" path is offered when parent-connect
      # is on and its placement includes the start edge.
      def parent_connect_on_start?
        capabilities.parent_connect? && %i[both start].include?(parent_connect_placement)
      end

      # The review-step parent section is offered when parent-connect is on and its
      # placement includes the review edge.
      def parent_connect_on_review?
        capabilities.parent_connect? && %i[both review].include?(parent_connect_placement)
      end

      def redirects_available?(form = nil)
        return false unless Hyrax.config.redirects_active?

        target = form.respond_to?(:model) ? form.model : form
        target.nil? || target.respond_to?(:redirects)
      end
    end
  end
end
