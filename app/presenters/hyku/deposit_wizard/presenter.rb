# frozen_string_literal: true

module Hyku
  module DepositWizard
    # Request-scoped view-model for the guided deposit wizard: the controller and
    # views share one object (+deposit_wizard.work_form+) rather than a pile of
    # global helper methods. It composes Config and State and delegates request
    # primitives to the controller context (some Hyrax services need it as scope).
    class Presenter
      delegate :current_user, :current_ability, :session, :params, :main_app,
               :blacklight_config, to: :context

      def initialize(context)
        @context = context
      end

      def config
        Hyku::DepositWizard.config
      end

      def state
        @state ||= State.new(session[:deposit_wizard] ||= {})
      end

      private

      attr_reader :context
    end
  end
end
