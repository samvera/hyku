# frozen_string_literal: true

module Hyrax
  # Guided, multi-step deposit wizard. A config-driven alternative entry point to
  # depositing works; the underlying persistence still runs through the public
  # Hyrax create transaction, so a work created here is indistinguishable from
  # one created via the stock deposit form. Gated by the +deposit_wizard+
  # Flipflop feature (off by default).
  class DepositWizardController < ApplicationController
    include Hyrax::DepositWizard::Context

    with_themed_layout 'dashboard'

    before_action :ensure_enabled
    before_action :authenticate_user!
    before_action :build_breadcrumbs

    STEPS = %w[start item_start known_type files details review done].freeze
    STEPS_REQUIRING_WORK_TYPE = %w[files details review].freeze

    # Let the details step reuse Hyrax's work-form partials: the shared
    # _form_metadata renders sub-partials (form_media, etc.) by relative name,
    # which must resolve against hyrax/base.
    def self._prefixes
      super + ['hyrax/base']
    end

    def start
      reset_state
      render :start
    end

    def show
      step = params[:step].to_s
      return redirect_to(main_app.deposit_wizard_path) unless STEPS.include?(step)
      return redirect_to(main_app.deposit_wizard_step_path(step: 'known_type')) if needs_work_type?(step)

      build_work_form if %w[details review].include?(step)
      render step
    end

    # Record a choice made on the current step and advance to the next one. The
    # wizard is server-rendered: each step is a GET, and choices POST here.
    def update
      case params[:step].to_s
      when 'start'      then advance_from_start
      when 'item_start' then advance_from_item_start
      when 'known_type' then advance_from_known_type
      when 'files'      then advance_from_files
      when 'details'    then advance_from_details
      else redirect_to main_app.deposit_wizard_path
      end
    end

    # Persist the work from the collected state, then run the configured
    # post-commit hook (e.g. Enact nesting) and land on the done screen.
    def commit
      return redirect_to(main_app.deposit_wizard_step_path(step: 'known_type')) if wizard_state.work_type.blank?

      build_work_form
      if deposit_agreement_required? && params[:agreement] != '1'
        flash.now[:alert] = t('hyku.deposit_wizard.errors.agreement_required')
        return render(:review)
      end

      work = create_work
      return render(:review) unless work

      wizard_config.post_commit&.call(work, wizard_state)
      reset_state
      stash_deposited(work)
      redirect_to main_app.deposit_wizard_step_path(step: 'done')
    end

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
        redirect_to main_app.deposit_wizard_step_path(step: 'review')
      else
        render :details
      end
    end

    # Mirror Hyrax's batch-upload guard: redirect to the dashboard rather than
    # exposing the wizard routes when the feature is off.
    def ensure_enabled
      return if Flipflop.deposit_wizard?

      redirect_to hyrax.my_works_path, alert: t('hyku.deposit_wizard.disabled')
    end

    def build_breadcrumbs
      add_breadcrumb t('hyrax.controls.home'), main_app.root_path
      add_breadcrumb t('hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t('hyku.deposit_wizard.button'), main_app.deposit_wizard_path
    end

    def reset_state
      session[:deposit_wizard] = {}
    end
  end
end
