# frozen_string_literal: true

module Hyrax
  module DepositWizard
    # Step-to-step transitions: each advance_from_<step> records that step's
    # choice into wizard state and redirects to the next step. The wizard is
    # server-rendered, so these run from the controller's #update action.
    module Navigation
      extend ActiveSupport::Concern

      private

      def advance_from_start
        wizard_state.admin_set_id = params[:admin_set_id] if params.key?(:admin_set_id)
        if wizard_config.container?
          wizard_state.path = params[:path]
          redirect_to main_app.deposit_wizard_step_path(step: 'item_start')
        else
          wizard_state.path = 'standalone'
          select_work_type_and_continue
        end
      end

      def advance_from_item_start
        redirect_to main_app.deposit_wizard_step_path(step: 'known_type')
      end

      def advance_from_known_type
        select_work_type_and_continue
      end

      def select_work_type_and_continue
        type = params[:work_type].to_s
        unless available_work_types.map(&:to_s).include?(type)
          flash.now[:alert] = t('hyku.deposit_wizard.errors.no_work_type')
          return render(wizard_config.container? ? :known_type : :start)
        end

        wizard_state.work_type = type
        redirect_to main_app.deposit_wizard_step_path(step: 'files'),
                    notice: t('hyku.deposit_wizard.notices.work_type_selected', type: type.constantize.model_name.human)
      end

      def advance_from_files
        # `uploaded_files[]` is emitted by Hyrax's upload js_templates for each
        # completed upload, matching the param name stock deposit uses.
        wizard_state.uploaded_file_ids = params[:uploaded_files]
        wizard_state.primary_file_id = params[:primary_file_id]
        redirect_to main_app.deposit_wizard_step_path(step: 'details')
      end

      # The ChangeSet permits its own fields, so raw nested params go straight to
      # #validate, as the stock works controller does. The submitted values (plain
      # strings/arrays) are stored so they serialize into the session.
      def advance_from_details
        build_work_form
        if @form.validate(work_params)
          wizard_state.attributes = work_params.to_unsafe_h
          next_step = wizard_state.uploaded_file_ids.any? ? 'file_meta' : 'review'
          redirect_to main_app.deposit_wizard_step_path(step: next_step)
        else
          render :details
        end
      end

      def advance_from_file_meta
        submitted = params.fetch(:file_metadata, {}).permit!.to_h
        allowed = wizard_state.uploaded_file_ids.map(&:to_s)
        wizard_state.file_metadata = submitted.slice(*allowed)
        redirect_to main_app.deposit_wizard_step_path(step: 'review')
      end
    end
  end
end
