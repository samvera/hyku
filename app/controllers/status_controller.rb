# frozen_string_literal: true

class StatusController < ApplicationController
  layout 'hyrax/dashboard'

  before_action do
    authorize! :read, :admin_dashboard
  end

  def index
    add_breadcrumb t(:'hyrax.controls.home'), root_path
    add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
    add_breadcrumb t(:'hyrax.admin.sidebar.system_status'), main_app.status_path
  end
end
