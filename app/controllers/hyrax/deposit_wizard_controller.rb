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

    STEPS = %w[start].freeze

    def start
      reset_state
      render :start
    end

    def show
      step = params[:step].to_s
      return redirect_to(main_app.deposit_wizard_path) unless STEPS.include?(step)

      render step
    end

    private

    # The seam downstream apps replace to add container types, suggestions, etc.
    def wizard_config
      Hyku::DepositWizard.config
    end
    helper_method :wizard_config

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
