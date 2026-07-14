# frozen_string_literal: true

module Hyrax
  module DepositWizard
    # Controller-side access to the wizard presenter for the names the controller
    # and the remaining concerns still call. Views reach the presenter directly as
    # deposit_wizard.*, so these are no longer exposed as helper methods.
    module Context
      extend ActiveSupport::Concern

      included do
        delegate :available_work_types, :work_form, :build_work_form, :uploaded_files,
                 :selected_admin_set_id, :item_flow_entry_step, :item_start_offers_choice?,
                 :eligible_parent_documents, to: :deposit_wizard

        def wizard_config
          deposit_wizard.config
        end

        def wizard_state
          deposit_wizard.state
        end

        def needs_work_type?(step)
          self.class::STEPS_REQUIRING_WORK_TYPE.include?(step) && wizard_state.work_type.blank?
        end
      end
    end
  end
end
