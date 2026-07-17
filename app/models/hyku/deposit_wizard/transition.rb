# frozen_string_literal: true

module Hyku
  module DepositWizard
    # The outcome of advancing from a wizard step: either move on to +step+
    # (optionally flashing a notice), or re-render +step+ with an alert because
    # the submitted choice was rejected. The presenter decides which; the
    # controller turns it into a redirect or a render.
    class Transition
      def self.advance(step, notice: nil)
        new(step: step, notice: notice)
      end

      def self.rerender(step, alert:, messages: nil)
        new(step: step, alert: alert, messages: messages, advance: false)
      end

      attr_reader :step, :notice, :alert, :messages

      def initialize(step:, notice: nil, alert: nil, messages: nil, advance: true)
        @step = step
        @notice = notice
        @alert = alert
        @messages = messages
        @advance = advance
      end

      def advance?
        @advance
      end
    end
  end
end
