# frozen_string_literal: true

module Hyrax
  module DepositWizard
    # Wizard context shared by the controller and its views: the active config,
    # per-request state, the work-type list, the stepper rail, and the work form.
    module Context
      extend ActiveSupport::Concern

      included do
        helper_method :wizard_config, :wizard_state, :available_work_types,
                      :item_stepper_steps, :work_form, :last_deposited,
                      :available_admin_sets, :selected_admin_set_id, :selected_admin_set_name
      end

      # The seam downstream apps replace to add container types, suggestions, etc.
      def wizard_config
        Hyku::DepositWizard.config
      end

      def wizard_state
        @wizard_state ||= Hyku::DepositWizard::State.new(session[:deposit_wizard] ||= {})
      end

      # The work types the current user may create, exactly as the stock deposit
      # chooser lists them (tenant- and profile-filtered).
      def available_work_types
        Hyrax::QuickClassificationQuery.new(current_user).authorized_models
      end

      # Stepper rail for the single-item flow: item type -> upload -> detail ->
      # review. Portfolio and batch flows have their own step sets.
      def item_stepper_steps
        %i[type upload detail review].each_with_index.map do |key, i|
          { n: i + 1, label: t("hyku.deposit_wizard.stepper.item.#{key}") }
        end
      end

      def work_form
        @form
      end

      # Build the ResourceForm for the chosen work type, re-validating any values
      # entered on a prior visit so the fields render prepopulated. Passing
      # admin_set_id to +ResourceForm.for+ applies its contexts during form init
      # (in flexible mode those contexts determine which fields the form exposes),
      # which is the same lifecycle point the stock works controller uses.
      def build_work_form
        @form = Hyrax::Forms::ResourceForm.for(resource: work_resource_class.new,
                                               admin_set_id: selected_admin_set_id).prepopulate!
        @form.validate(wizard_state.attributes) if wizard_state.attributes.present?
        # The flexible metadata form's shared/_schema_version widget reads this
        # ivar (stock sets it in a new/edit before_action, which the wizard lacks).
        @latest_schema_version = Hyrax::FlexibleSchema.current_schema_id.to_f
      end

      # The admin set to deposit into: the user's explicit choice, else the
      # default admin set (matching the stock deposit modal's preselection).
      def selected_admin_set_id
        wizard_state.admin_set_id.presence || default_admin_set_id
      end

      def default_admin_set_id
        Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s
      rescue StandardError
        available_admin_sets.first&.dig(1)&.to_s
      end

      # The display name of the selected admin set, for the review destination.
      def selected_admin_set_name
        id = selected_admin_set_id
        available_admin_sets.find { |_label, option_id, *| option_id.to_s == id.to_s }&.first
      end

      # The chooser lists ActiveFedora model names, but the form needs the
      # Valkyrie resource class. Resolve by shared param_key against the
      # registered Valkyrie work classes (no Wings), falling back to the chosen
      # class when no Valkyrie class is registered.
      def work_resource_class
        chosen = wizard_state.work_type.constantize
        return chosen if chosen < Hyrax::Resource

        Hyrax::ModelRegistry.work_classes.detect do |klass|
          klass < Hyrax::Resource && klass.model_name.param_key == chosen.model_name.param_key
        end || chosen
      end

      # Active deposit-agreement mode requires the depositor to tick the checkbox
      # before committing; passive mode is informational only.
      def deposit_agreement_required?
        Flipflop.show_deposit_agreement? && Flipflop.active_deposit_agreement_acceptance?
      end

      def work_params
        params.fetch(wizard_state.work_type.constantize.model_name.param_key, {})
      end

      # Run the stock CreateValkyrieWork action (same as the deposit form) to
      # persist the work and attach the uploaded files. Returns the work, or nil
      # when validation or the transaction fails.
      def create_work
        action = Hyrax::Action::CreateValkyrieWork.new(form: work_form,
                                                       transactions: Hyrax::Transactions::Container,
                                                       user: current_user,
                                                       params: commit_params,
                                                       work_attributes_key: work_form.model_name.param_key)
        return unless action.validate

        action.perform.value_or(nil)
      end

      # Survive the redirect to the done screen, which reads it once. The show
      # path is built here where the work object is available.
      def stash_deposited(work)
        session[:deposit_wizard_last] = {
          'title' => Array(work.title).first,
          'path' => main_app.polymorphic_path([main_app, work])
        }
      end

      # The params CreateValkyrieWork expects, assembled from wizard state: the
      # work attributes (with the chosen admin set) under its param key, plus the
      # uploaded-file ids to attach.
      def commit_params
        attributes = wizard_state.attributes.merge('admin_set_id' => selected_admin_set_id).compact
        ActionController::Parameters.new(
          work_form.model_name.param_key => attributes,
          'uploaded_files' => wizard_state.uploaded_file_ids
        )
      end

      # The admin sets the current user may deposit into, as selection options.
      # Shown as an inline chooser only when more than one is available.
      def available_admin_sets
        @available_admin_sets ||=
          Hyrax::AdminSetSelectionPresenter.new(admin_sets: admin_sets_for_deposit).select_options
      end

      def admin_sets_for_deposit
        Hyrax::AdminSetService.new(self).search_results(:deposit)
      end

      # The just-deposited work info, stashed for the done screen and read once.
      def last_deposited
        session.delete(:deposit_wizard_last)
      end

      def needs_work_type?(step)
        self.class::STEPS_REQUIRING_WORK_TYPE.include?(step) && wizard_state.work_type.blank?
      end
    end
  end
end
