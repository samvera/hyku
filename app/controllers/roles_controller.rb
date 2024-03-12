# frozen_string_literal: true

##
# CRUD actions for assigning exhibit roles to
# existing users
class RolesController < ApplicationController
  load_and_authorize_resource :user, parent: false
  layout 'hyrax/dashboard'

  before_action do
    authorize! :manage, Role
  end

  def index
    @users = User.all
    add_breadcrumb t(:'hyrax.controls.home'), root_path
    add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
    add_breadcrumb t(:'hyrax.admin.sidebar.roles_and_permissions'), site_roles_path
  end

  def update
    if @user.update(user_params)
      redirect_to site_roles_path, notice: notice
    else
      render action: 'index'
    end
  end

  protected

  def user_params
    params.require(:user).permit(site_roles: [])
  end
end
