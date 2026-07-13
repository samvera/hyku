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

      # e.g. invalid redirect path or video embed the form validator rejected.
      def form_error_messages(form)
        form.errors.full_messages
      end

      # A transaction Failure's first element is a symbol reason (e.g.
      # :redirect_path_collision); prefer a translation for it, else its detail.
      def transaction_failure_messages(failure)
        reason, *detail = Array(failure)
        message = I18n.t("hyku.deposit_wizard.errors.commit.#{reason}", default: nil) ||
                  Array(detail).flatten.map(&:to_s).presence&.to_sentence || reason.to_s.humanize
        Array(message)
      end
    end
  end
end
