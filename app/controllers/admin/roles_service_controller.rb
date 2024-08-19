# frozen_string_literal: true

module Admin
  class RolesServiceController < ApplicationController
    layout 'hyrax/dashboard'

    def index
      authorize! :update, RolesService
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.roles_service_jobs'), main_app.admin_roles_service_jobs_path
    end

    # post "admin/roles_service/:job_name_key
    def update_roles
      authorize! :update, RolesService
      job = RolesService.valid_jobs.fetch(params[:job_name_key])

      job.perform_later

      respond_to do |wants|
        wants.html { redirect_to main_app.admin_roles_service_jobs_path, notice: "#{job} has been submitted." }
        wants.json { render json: { notice: "#{job} has been submitted." }, status: :ok }
      end
    end
  end
end
