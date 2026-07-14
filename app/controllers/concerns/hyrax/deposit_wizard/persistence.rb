# frozen_string_literal: true

module Hyrax
  module DepositWizard
    # The commit-side controller glue that reads params or writes the session; the
    # work-building itself lives on Hyku::DepositWizard::Presenter.
    module Persistence
      extend ActiveSupport::Concern

      def work_params
        params.fetch(wizard_state.work_type.constantize.model_name.param_key, {})
      end

      # Survive the redirect to the done screen, which reads it once. The show
      # path is built here where the work object is available.
      def stash_deposited(work)
        session[:deposit_wizard_last] = {
          'title' => Array(work.title).first,
          'path' => main_app.polymorphic_path([main_app, work])
        }
      end
    end
  end
end
