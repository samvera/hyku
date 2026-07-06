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

      def initialize
        @single_admin_set = true
        @enable_batch = false
        @file_pool = false
        @file_meta = false
        @container_type = nil
        @item_types = nil
        @suggestions = {}
        @post_commit = nil
        yield self if block_given?
      end

      def container?
        container_type.present?
      end
    end
  end
end
