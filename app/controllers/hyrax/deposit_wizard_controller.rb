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
      return redirect_to(step_path('select_parent')) if skip_start_for_handoff?

      assign_admin_sets_for_standard_chooser
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
      return head(:forbidden) unless wizard_config.parent_connect?

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

    # Abandon an in-progress deposit.
    def discard
      deleted = discard_staged_uploads
      reset_state
      key = deleted.positive? ? 'discarded_with_files' : 'discarded'
      redirect_to hyrax.my_works_path, notice: t("hyku.deposit_wizard.#{key}", count: deleted)
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

      # Stash before resetting, so reading the session-scoped parent doesn't rely
      # on the memoized State still pointing at the hash reset_state replaced.
      stash_deposited(work)
      reset_state
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
      return if wizard_config.enabled?

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

    # Staged uploads are only reachable through this session, so abandoning the
    # deposit orphans them: nothing will attach them to a work, and the cleanup
    # sweeper's default retention is measured in years.
    #
    # Scoped by user (matching the `can :destroy, UploadedFile, user: current_user`
    # ability) because the ids come from the session, which a request can forge.
    # Returns the number destroyed, so the notice can name what actually happened.
    def discard_staged_uploads
      ids = wizard_state.uploaded_file_ids
      return 0 if ids.blank?

      staged = Hyrax::UploadedFile.where(id: ids, user: current_user)
      staged.count.tap { staged.find_each(&:destroy) }
    end

    # Survive the redirect to the done screen, which reads it once. The show path
    # is built here where the work object is available. The ids let a done-screen
    # override render something about the deposit in context (e.g. the parent's
    # membership) without re-deriving them from state the redirect has dropped.
    def stash_deposited(work)
      session[:deposit_wizard_last] = {
        'id' => work.id.to_s,
        'parent_id' => wizard_state.parent_id.presence,
        'title' => Array(work.title).first,
        'path' => main_app.polymorphic_path([main_app, work])
      }
    end

    # The "switch to the standard deposit form" link reuses Hyrax's
    # select_work_type_modal, whose admin-set dropdown reads this ivar (mirroring
    # My::WorksController). Only needed when that link is shown.
    def assign_admin_sets_for_standard_chooser
      return unless wizard_config.standard_link?

      @admin_sets_for_select = helpers.available_admin_sets_for_creating_works(ability: current_ability)
    end

    # Seed wizard state from the same context params other entry points pass
    # allowing a potential connection point with other deposit flows.
    #
    # A present +parent_id+ / +add_works_to_collection+ is a directed handoff
    # ("attach a child to THIS work" / "deposit into THIS collection") and always
    # seeds; it is independent of the +parent_connect+ / +collection_connect+
    # capabilities, which only govern the optional start/review pickers a depositor
    # uses to choose a parent or collections themselves.
    def seed_launch_context
      seed_parent_handoff if params[:parent_id].present?

      return if params[:add_works_to_collection].blank?

      wizard_state.attributes = wizard_state.attributes.merge(
        'member_of_collections_attributes' => { '0' => { 'id' => params[:add_works_to_collection] } }
      )
    end

    # Setting the 'add' path is required, not redundant with parent_id: without it
    # select_parent is skipped and its on_skip: :entry detour bounces straight back
    # here.
    def seed_parent_handoff
      wizard_state.parent_id = params[:parent_id]
      wizard_state.path = 'add'
      inherit_admin_set_from_parent
    end

    # Skipping `start` skips its inline admin-set chooser, so a child work takes
    # its parent's admin set. selected_admin_set_id falls back to the default when
    # this leaves it blank (an unreadable or since-deleted parent).
    def inherit_admin_set_from_parent
      parent = Hyrax.query_service.find_by(id: wizard_state.parent_id)
      wizard_state.admin_set_id = parent.try(:admin_set_id).presence
    rescue Valkyrie::Persistence::ObjectNotFoundError
      nil
    end

    # Land a directed handoff on the parent step rather than the path chooser it
    # has already answered.
    #
    # Only for installs that choose a parent up front. The default placement
    # (:review) accepts a handed-off parent and proceeds, which is deliberate —
    # redirecting those installs to an up-front parent step would contradict it.
    def skip_start_for_handoff?
      # The param, so Back from select_parent (which returns here without one)
      # reaches the chooser instead of being redirected forward in a loop; the
      # state too, since parent_id= drops a blank and there'd be nothing to show.
      params[:parent_id].present? &&
        wizard_config.parent_connect_on_start? &&
        wizard_state.parent_id.present?
    end
  end
end
