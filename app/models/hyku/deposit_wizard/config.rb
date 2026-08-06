# frozen_string_literal: true

module Hyku
  module DepositWizard
    # Configuration seam for the guided deposit wizard. See
    # docs/deposit-wizard.md for the full option reference and insertion points.
    # Downstream apps replace the shared instance via +Hyku::DepositWizard.config+.
    class Config
      # Capabilities read live from Flipflop on every call — never stored on the
      # config — so toggling a flag takes effect immediately. (Static deployment
      # settings, including parent/collection connect, live on Config itself.)
      module Capabilities
        module_function

        # The guided wizard is on exactly when enable_guided_deposit is on: this
        # gates its routes/start page and the dependent pickers. When on, guided also
        # takes over every non-works-page deposit entry link (see
        # guided_replaces_standard?).
        def enabled?
          Flipflop.enable_guided_deposit?
        end

        # Guided overrides the standard deposit entry links whenever it is enabled;
        # the entry-point views ask this to decide where their links point.
        def guided_replaces_standard?
          enabled?
        end

        # The standard-deposit button on the works page — independent of guided.
        def standard_deposit_button?
          Flipflop.enable_standard_deposit?
        end

        # The "switch to the standard deposit form" link on the guided start screen:
        # offered when both deposit paths are enabled, so a guided depositor can opt
        # into the standard form the tenant also offers.
        def standard_link?
          enabled? && standard_deposit_button?
        end
      end

      attr_accessor :container_type, :item_types, :suggestions,
                    :post_commit, :parent_types, :parent_connect_placement
      attr_writer :flow, :parent_connect, :collection_connect, :depositor_sharing

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

      # Consumers talk to +config+ as the single surface for every deposit-mode
      # question, whether it resolves to a live Flipflop capability (delegated here)
      # or a static setting (parent_connect? / collection_connect? / sharing? below).
      delegate :enabled?, :guided_replaces_standard?, :standard_deposit_button?, :standard_link?,
               to: :capabilities

      def initialize
        @container_type = nil
        @item_types = nil
        @suggestions = {}
        @post_commit = nil
        @parent_types = nil
        @parent_connect_placement = :review
        @parent_connect = true
        @collection_connect = true
        @depositor_sharing = true
        yield self if block_given?
      end

      def container?
        container_type.present?
      end

      # Whether the wizard offers a parent picker / a collection picker. Static
      # deployment settings (default on), not Flipflop capabilities — an app opts
      # out in its initializer.
      def parent_connect?
        @parent_connect
      end

      def collection_connect?
        @collection_connect
      end

      # Whether the wizard offers the sharing (per-user/group access) section on the
      # review step. A static setting (default on), gated by the wizard being enabled.
      def sharing?
        enabled? && @depositor_sharing
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
        parent_connect? && %i[both start].include?(parent_connect_placement)
      end

      # The review-step parent section is offered when parent-connect is on and its
      # placement includes the review edge.
      def parent_connect_on_review?
        parent_connect? && %i[both review].include?(parent_connect_placement)
      end

      def redirects_available?(form = nil)
        return false unless Hyrax.config.redirects_active?

        target = form.respond_to?(:model) ? form.model : form
        target.nil? || target.respond_to?(:redirects)
      end
    end
  end
end
