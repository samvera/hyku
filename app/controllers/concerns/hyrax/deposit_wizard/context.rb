# frozen_string_literal: true

module Hyrax
  module DepositWizard
    # Bridges the wizard's view/data logic to Hyku::DepositWizard::Presenter during
    # the migration off these controller concerns: the controller and remaining
    # concerns still call these names, and they delegate to the single presenter
    # instance. Views now call deposit_wizard.* directly.
    module Context
      extend ActiveSupport::Concern

      DELEGATED = %i[
        available_work_types item_stepper_steps stepper_phase work_form build_work_form
        uploaded_files file_meta_forms file_inherits_visibility? file_display_title
        file_visibility_summaries work_visibility_attributes selected_admin_set_id
        selected_admin_set_name available_admin_sets admin_set_options_for_display
        multiple_admin_sets? show_relationship_paths? item_flow_entry_step
        item_start_offers_choice? known_type_back_step selected_member_collections
        saved_permission_grants collection_display_title selected_parent_title
        selected_parent extra_prefilled? eligible_parent_documents last_deposited
      ].freeze

      included do
        delegate(*DELEGATED, to: :deposit_wizard)
        helper_method(*DELEGATED, :wizard_config, :wizard_state)

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
