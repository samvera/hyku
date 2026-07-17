# frozen_string_literal: true

module Hyku
  # Namespace for the guided deposit wizard. Holds the shared, swappable
  # configuration read by the wizard controller and views.
  module DepositWizard
    class << self
      def config
        @config ||= Config.new
      end

      attr_writer :config

      # Reset to the default configuration (used by specs).
      def reset_config!
        @config = nil
      end
    end
  end
end
