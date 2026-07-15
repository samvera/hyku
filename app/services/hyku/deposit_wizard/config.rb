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

      attr_accessor :single_admin_set, :enable_batch, :file_pool, :file_meta,
                    :container_type, :item_types, :suggestions, :post_commit, :parent_types,
                    :parent_connect_placement

      # Where the parent-connect capability offers to attach a parent: :both
      # (default), :start (only the up-front "add to an existing work" path),
      # :review (only the review-step section), or :none. Only takes effect when
      # parent-connect is enabled.
      PARENT_CONNECT_PLACEMENTS = %i[both start review none].freeze

      def capabilities
        Capabilities
      end

      def initialize
        @single_admin_set = true
        @enable_batch = false
        @file_pool = false
        @file_meta = false
        @container_type = nil
        @item_types = nil
        @suggestions = {}
        @post_commit = nil
        @parent_types = nil
        @parent_connect_placement = :both
        yield self if block_given?
      end

      def container?
        container_type.present?
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
