# frozen_string_literal: true

module Hyku
  module DepositWizard
    # Configuration seam for the guided deposit wizard.
    #
    # A plain Hyku install gets a usable flat wizard: any enabled work type, no
    # container path, no file pool. Downstream apps (e.g. the Enact knapsack)
    # replace the shared instance with their own configuration to add
    # container-like work types, subtype/suggestion maps, and a post-commit hook.
    #
    #   Hyku::DepositWizard.config = Hyku::DepositWizard::Config.new do |c|
    #     c.container_type = Portfolio
    #     c.file_pool = true
    #     c.file_meta = true
    #     c.post_commit = ->(work, wizard) { ... }
    #   end
    #
    # The wizard reads the shared instance via +Hyku::DepositWizard.config+.
    class Config
      # Offer only the primary admin set (v5 +singleAdminSet+ prop).
      attr_accessor :single_admin_set

      # Offer the "many files, one type" batch sub-flow (v5 +enableBatch+ prop).
      attr_accessor :enable_batch

      # Offer an upfront shared upload pool at the container level (v5 +filePool+).
      attr_accessor :file_pool

      # Collect per-file FileSet metadata inline before commit (v5 +file_meta+).
      attr_accessor :file_meta

      # The container work type (class or class name); +nil+ means a flat wizard
      # with no container path.
      attr_accessor :container_type

      # Child/item work types (array of class names); +nil+ falls back to the
      # tenant's enabled work types at request time.
      attr_accessor :item_types

      # File-category => ordered subtype-id suggestions for the guided flow
      # (v5 +SUGGEST+ map).
      attr_accessor :suggestions

      # Callable run after commit, receiving the persisted work and wizard state.
      attr_accessor :post_commit

      # The parent/collection/sharing capabilities are per-tenant Flipflop features
      # (grouped with :deposit_wizard). A writer stays for an explicit in-memory
      # override (used by specs and any app that sets it directly). Redirects are
      # not here — they use their own Flipflop gate (see #redirects_available?).
      attr_writer :enable_parent_connect, :enable_collection_connect, :enable_sharing

      # Work types eligible as parents; +nil+ falls back to the tenant's available
      # work types.
      attr_accessor :parent_types

      # Each reader returns the in-memory override when one was set, otherwise the
      # tenant's Flipflop feature value.
      %i[parent_connect collection_connect sharing].each do |capability|
        define_method("enable_#{capability}") do
          override = instance_variable_get("@enable_#{capability}")
          return override unless override.nil?

          Flipflop.public_send("deposit_wizard_#{capability}?")
        end
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
        yield self if block_given?
      end

      def container?
        container_type.present?
      end

      def redirects_available?(form = nil)
        return false unless Hyrax.config.redirects_active?

        target = form.respond_to?(:model) ? form.model : form
        target.nil? || target.respond_to?(:redirects)
      end
    end
  end
end
