# frozen_string_literal: true

module Hyrax
  # Guided, multi-step deposit wizard. A config-driven alternative entry point to
  # depositing works; the underlying persistence still runs through the public
  # Hyrax create transaction, so a work created here is indistinguishable from
  # one created via the stock deposit form. Gated by the +deposit_wizard+
  # Flipflop feature (off by default).
  class DepositWizardController < ApplicationController # rubocop:disable Metrics/ClassLength
    # The presenter is the single object the controller and views share; these
    # delegate the couple of names the controller still calls by bare name. Views
    # reach the presenter directly as deposit_wizard.*.
    delegate :build_work_form, :eligible_parent_documents, to: :deposit_wizard

    with_themed_layout 'dashboard'

    before_action :ensure_enabled
    before_action :authenticate_user!
    before_action :assign_current_ability
    before_action :build_breadcrumbs

    # Let the details step reuse Hyrax's work-form partials: the shared
    # _form_metadata renders sub-partials (form_media, etc.) by relative name,
    # which must resolve against hyrax/base.
    def self._prefixes
      super + ['hyrax/base']
    end

    def start
      reset_state
      seed_launch_context
      render :start
    end

    def show
      step = params[:step].to_s
      return redirect_to(main_app.deposit_wizard_path) unless deposit_wizard.valid_step?(step)

      detour = deposit_wizard.step_detour(step)
      return redirect_to(step_path(detour)) if detour

      if %w[details review].include?(step)
        build_work_form
        # Hyrax's shared/_schema_version partial reads this controller ivar directly.
        @latest_schema_version = deposit_wizard.latest_schema_version
      end
      render step
    end

    # Record a choice made on the current step and advance to the next one. The
    # wizard is server-rendered: each step is a GET, and choices POST here.
    def update
      transition = deposit_wizard.advance_from(params[:step].to_s)
      return redirect_to(main_app.deposit_wizard_path) if transition.nil?

      apply_transition(transition)
    end

    def parent_options
      return head(:forbidden) unless wizard_config.capabilities.parent_connect?

      # FindWorksSearchBuilder excludes a "current" work by params[:id]; the wizard
      # has no current work, so a blank id excludes nothing.
      params[:id] ||= ''
      render json: eligible_parent_documents(params[:q]).map { |doc| { id: doc.id, label: doc.title.first } }
    end

    # Autosave endpoint for the review-step extras, so they survive a refresh.
    def save_extras
      return head(:bad_request) if wizard_state.work_type.blank?

      build_work_form
      deposit_wizard.capture_review_extras
      head :no_content
    end

    # Deposit the work from the collected state and land on the done screen.
    def commit
      return redirect_to(main_app.deposit_wizard_step_path(step: 'known_type')) if wizard_state.work_type.blank?

      build_work_form
      return render(:review) unless deposit_agreement_accepted?

      deposit_wizard.capture_review_extras
      build_work_form
      work = deposit_wizard.deposit
      unless work
        flag_commit_failure(deposit_wizard.commit_errors)
        return render(:review)
      end

      reset_state
      stash_deposited(work)
      redirect_to main_app.deposit_wizard_step_path(step: 'done')
    end

    private

    def deposit_wizard
      @deposit_wizard ||= Hyku::DepositWizard::Presenter.new(self)
    end
    helper_method :deposit_wizard

    def wizard_config
      deposit_wizard.config
    end

    def wizard_state
      deposit_wizard.state
    end

    # Turn the presenter's Transition into the HTTP effect: advance by redirecting
    # to the next step, or flash the alert and re-render the current step.
    def apply_transition(transition)
      return redirect_to(step_path(transition.step), notice: transition.notice) if transition.advance?

      if transition.messages
        flash_error(transition.alert, transition.messages)
      else
        flash.now[:alert] = t(transition.alert)
      end
      render transition.step
    end

    # The 'start' step is the reset entry point (its own action), not a rendered
    # :step; everything else is the show route.
    def step_path(step)
      step == 'start' ? main_app.deposit_wizard_path : main_app.deposit_wizard_step_path(step: step)
    end

    # Route for the Back button on the step currently rendering: the flow's
    # previous visible step, so views never hardcode their predecessor.
    def wizard_back_path(current_step)
      back = deposit_wizard.back_step(current_step.to_s)
      back ? step_path(back) : main_app.deposit_wizard_path
    end
    helper_method :wizard_back_path

    # Mirror Hyrax's batch-upload guard: redirect to the dashboard rather than
    # exposing the wizard routes when the feature is off.
    def ensure_enabled
      return if Flipflop.deposit_wizard?

      redirect_to hyrax.my_works_path, alert: t('hyku.deposit_wizard.disabled')
    end

    # Hyrax's collection/search helpers (e.g. available_collections) read the
    # @current_ability instance variable, which stock works controllers set via
    # WorksControllerBehavior. This lean controller must set it itself, or those
    # helpers bail with an empty list.
    def assign_current_ability
      @current_ability = current_ability
    end

    def build_breadcrumbs
      add_breadcrumb t('hyrax.controls.home'), main_app.root_path
      add_breadcrumb t('hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t('hyku.deposit_wizard.button'), main_app.deposit_wizard_path
    end

    # False (with an alert flashed) when active-agreement mode requires the
    # checkbox and it wasn't ticked, so #commit can re-render review.
    def deposit_agreement_accepted?
      return true unless deposit_wizard.deposit_agreement_required? && params[:agreement] != '1'

      flash.now[:alert] = t('hyku.deposit_wizard.errors.agreement_required')
      false
    end

    # Set a multi-line alert: a lead-in ending in a colon, then one line per
    # message. _flash_msg joins an array flash with <br>, so each is its own row.
    def flash_error(lead_in_key, messages)
      flash.now[:alert] = ["#{t(lead_in_key)}:", *Array(messages)]
      nil
    end

    def flag_commit_failure(messages)
      flash_error('hyku.deposit_wizard.errors.deposit_failed', messages)
    end

    def reset_state
      session[:deposit_wizard] = {}
    end

    # Survive the redirect to the done screen, which reads it once. The show path
    # is built here where the work object is available.
    def stash_deposited(work)
      session[:deposit_wizard_last] = {
        'title' => Array(work.title).first,
        'path' => main_app.polymorphic_path([main_app, work])
      }
    end

    # Seed wizard state from the same context params other entry points pass
    # allowing a potential connection point with other deposit flows.
    def seed_launch_context
      wizard_state.parent_id = params[:parent_id] if wizard_config.capabilities.parent_connect? && params[:parent_id].present?

      return unless wizard_config.capabilities.collection_connect? && params[:add_works_to_collection].present?

      wizard_state.attributes = wizard_state.attributes.merge(
        'member_of_collections_attributes' => { '0' => { 'id' => params[:add_works_to_collection] } }
      )
    end
  end
end
