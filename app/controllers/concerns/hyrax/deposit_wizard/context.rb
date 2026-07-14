# frozen_string_literal: true

module Hyrax
  module DepositWizard
    # Controller-side access to the wizard presenter: the config/state shorthands
    # the controller reads, plus the couple of presenter methods it still calls by
    # bare name. Views reach the presenter directly as deposit_wizard.*.
    module Context
      extend ActiveSupport::Concern

      included do
        delegate :build_work_form, :eligible_parent_documents, to: :deposit_wizard

        def wizard_config
          deposit_wizard.config
        end

        def wizard_state
          deposit_wizard.state
        end
      end
    end
  end
end
