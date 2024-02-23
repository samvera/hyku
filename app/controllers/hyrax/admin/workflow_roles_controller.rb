# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.2 Expand to allow adding groups to workflow roles
module Hyrax
  module Admin
    class WorkflowRolesController < ApplicationController
      before_action :require_permissions
      with_themed_layout 'dashboard'

      def index
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.workflow_roles.header'), hyrax.admin_workflow_roles_path
        @presenter = WorkflowRolesPresenter.new
      end

      def destroy
        responsibility = Sipity::WorkflowResponsibility.find(params[:id])
        authorize! :destroy, responsibility
        responsibility.destroy
        redirect_to admin_workflow_roles_path
      end

      # OVERRIDE: Add WorkflowResponsibilityGroupForm
      def create
        authorize! :create, Sipity::WorkflowResponsibility

        # Determine which form it is, user or group
        form_params = params[:sipity_workflow_responsibility]
        form = if form_params[:user_id].present?
                 Forms::WorkflowResponsibilityForm.new(form_params)
               else
                 Forms::WorkflowResponsibilityGroupForm.new(form_params)
               end

        begin
          form.save!
        rescue ActiveRecord::RecordNotUnique
          logger.info "Not unique *****\n\n\n"
        end
        redirect_to admin_workflow_roles_path
      end

      private

        def require_permissions
          authorize! :read, :admin_dashboard
        end
    end
  end
end
