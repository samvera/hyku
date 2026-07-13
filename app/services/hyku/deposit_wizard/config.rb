# frozen_string_literal: true

module Hyku
  module DepositWizard
    # Configuration seam for the guided deposit wizard. See
    # docs/deposit-wizard.md for the full option reference and insertion points.
    # Downstream apps replace the shared instance via +Hyku::DepositWizard.config+.
    class Config
      attr_accessor :single_admin_set, :enable_batch, :file_pool, :file_meta,
                    :container_type, :item_types, :suggestions, :post_commit, :parent_types

      # The parent/collection/sharing capabilities are per-tenant Flipflop
      # features; a writer stays for an explicit in-memory override (specs, or an
      # app that sets it directly) that the reader below prefers over Flipflop.
      attr_writer :enable_parent_connect, :enable_collection_connect, :enable_sharing

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
