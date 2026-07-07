# frozen_string_literal: true

module Hyrax
  # Guided, multi-step deposit wizard. A config-driven alternative entry point to
  # depositing works; the underlying persistence still runs through the public
  # Hyrax create transaction, so a work created here is indistinguishable from
  # one created via the stock deposit form. Gated by the +deposit_wizard+
  # Flipflop feature (off by default).
  class DepositWizardController < ApplicationController
    with_themed_layout 'dashboard'

    before_action :ensure_enabled
    before_action :authenticate_user!
    before_action :build_breadcrumbs

    STEPS = %w[start item_start known_type files].freeze

    def start
      reset_state
      render :start
    end

    def show
      step = params[:step].to_s
      return redirect_to(main_app.deposit_wizard_path) unless STEPS.include?(step)

      # The files step (and everything after) needs a chosen work type; send the
      # user back to pick one rather than rendering an item-less upload page.
      return redirect_to(main_app.deposit_wizard_step_path(step: 'known_type')) if needs_work_type?(step)

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
      else redirect_to main_app.deposit_wizard_path
      end
    end

    private

    def needs_work_type?(step)
      step == 'files' && wizard_state.work_type.blank?
    end

    # The seam downstream apps replace to add container types, suggestions, etc.
    def wizard_config
      Hyku::DepositWizard.config
    end
    helper_method :wizard_config

    def wizard_state
      @wizard_state ||= Hyku::DepositWizard::State.new(session[:deposit_wizard] ||= {})
    end
    helper_method :wizard_state

    # Profile-filtered per tenant by Hyku's QuickClassificationQuery decorator.
    def available_work_types
      Hyrax::QuickClassificationQuery.new(current_user).authorized_models
    end
    helper_method :available_work_types

    # Stepper rail for the single-item flow. The full dynamic step sets
    # (portfolio / item with-or-without files / batch) arrive with those steps;
    # this increment covers the item type -> upload -> detail -> review shape.
    def item_stepper_steps
      %i[type upload detail review].each_with_index.map do |key, i|
        { n: i + 1, label: t("hyku.deposit_wizard.stepper.item.#{key}") }
      end
    end
    helper_method :item_stepper_steps

    def advance_from_start
      if wizard_config.container?
        wizard_state.path = params[:path]
        redirect_to main_app.deposit_wizard_step_path(step: 'item_start')
      else
        wizard_state.path = 'standalone'
        select_work_type_and_continue
      end
    end

    def advance_from_item_start
      # This increment supports the "known type" branch; guided/batch follow.
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

    # Record the uploaded files and which one is primary, then advance. The
    # files themselves are already persisted as Hyrax::UploadedFiles (uploaded to
    # /uploads as they were added); here we only capture their ids for commit.
    def advance_from_files
      # `uploaded_files[]` is emitted by Hyrax's upload js_templates for each
      # completed upload, matching the param name stock deposit uses.
      wizard_state.uploaded_file_ids = params[:uploaded_files]
      wizard_state.primary_file_id = params[:primary_file_id]
      redirect_to main_app.deposit_wizard_step_path(step: step_after_files)
    end

    # TODO(phase 3): return 'details' once the details step exists. Until then,
    # re-render files so the selection is not lost.
    def step_after_files
      'files'
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
