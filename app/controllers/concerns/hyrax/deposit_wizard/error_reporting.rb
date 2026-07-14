# frozen_string_literal: true

module Hyrax
  module DepositWizard
    # Turns wizard validation and transaction failures into a user-facing flash,
    # so a re-rendered step explains why it didn't advance rather than staying
    # silent. Shared by the details step (Navigation) and commit (Persistence).
    module ErrorReporting
      extend ActiveSupport::Concern

      private

      # Set a multi-line alert: a lead-in ending in a colon, then one line per
      # message. _flash_msg joins an array flash with <br>, so each is its own row.
      def flash_error(lead_in_key, messages)
        flash.now[:alert] = ["#{t(lead_in_key)}:", *Array(messages)]
        nil
      end

      def flag_commit_failure(messages)
        flash_error('hyku.deposit_wizard.errors.deposit_failed', messages)
      end
    end
  end
end
