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

        unless params.key?(:path)
          wizard_state.path = 'standalone'
          return select_work_type_and_continue
        end

        wizard_state.path = params[:path]
        if wizard_state.path == 'add'
          redirect_to main_app.deposit_wizard_step_path(step: 'select_parent')
        else
          redirect_to main_app.deposit_wizard_step_path(step: item_flow_entry_step)
        end
      end

      def advance_from_select_parent
        if params[:parent_id].blank?
          flash.now[:alert] = t('hyku.deposit_wizard.errors.no_parent')
          return render(:select_parent)
        end

        wizard_state.parent_id = params[:parent_id]
        redirect_to main_app.deposit_wizard_step_path(step: item_flow_entry_step)
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
          # Re-render whichever step posted the (invalid) type: the flat start
          # screen chooses the type inline, every other flow uses known_type.
          return render(params[:step].to_s == 'start' ? :start : :known_type)
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
        if work_form.validate(work_params)
          wizard_state.attributes = work_params.to_unsafe_h
          next_step = wizard_state.uploaded_file_ids.any? ? 'file_meta' : 'review'
          redirect_to main_app.deposit_wizard_step_path(step: next_step)
        else
          flash_error('hyku.deposit_wizard.errors.details_invalid', deposit_wizard.form_error_messages(work_form))
          render :details
        end
      end

      def advance_from_file_meta
        submitted = params.fetch(:file_metadata, {}).permit!.to_h
        allowed = wizard_state.uploaded_file_ids.map(&:to_s)
        wizard_state.file_metadata = submitted.slice(*allowed)
        redirect_to main_app.deposit_wizard_step_path(step: 'review')
      end

      # Capture the enabled connect/share/redirect capabilities posted with the
      # deposit form into wizard state before commit.
      def capture_review_extras
        keys = enabled_extra_attribute_keys
        if keys.any?
          posted = params.fetch(work_form.model_name.param_key, {}).permit!.to_h
          attributes = wizard_state.attributes
          # Delete-when-absent (not merge) so removing all of a capability's
          # entries clears it rather than leaving the prior value to reappear.
          keys.each { |key| posted.key?(key) ? attributes[key] = posted[key] : attributes.delete(key) }
          wizard_state.attributes = attributes
        end

        # Guard on params.key? so an absent parent_id doesn't clobber one seeded at
        # launch (the handoff).
        return unless wizard_config.enable_parent_connect && params.key?(:parent_id)
        wizard_state.parent_id = params[:parent_id]
      end

      def enabled_extra_attribute_keys
        keys = []
        keys << 'member_of_collections_attributes' if wizard_config.enable_collection_connect
        keys << 'permissions_attributes' if wizard_config.enable_sharing
        keys.push('redirects_attributes', 'redirects_display_url_index') if wizard_config.redirects_available?
        keys
      end
    end
  end
end
