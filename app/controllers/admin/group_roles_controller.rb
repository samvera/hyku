# frozen_string_literal: true

module Admin
  class GroupRolesController < ApplicationController
    before_action :load_group
    before_action :cannot_remove_admin_role_from_admin_group, only: [:destroy]
    layout 'hyrax/dashboard'

    rescue_from ActiveRecord::RecordNotFound, with: :redirect_not_found

    def index
      authorize! :edit, Hyrax::Group
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyku.admin.groups.title.edit'), edit_admin_group_path(@group)
      add_breadcrumb t(:'hyku.admin.groups.title.roles'), request.path

      @roles = ::Role.site - @group.roles
      render template: 'admin/groups/roles'
    end

    def create
      role = ::Role.find(params[:role_id])
      @group.roles << role unless @group.roles.include?(role)

      respond_to do |format|
        format.html do
          flash[:notice] = 'Role has successfully been added to Group'
          redirect_to admin_group_roles_path(@group)
        end
      end
    end

    def destroy
      @group.group_roles.find_by!(role_id: params[:role_id]).destroy

      respond_to do |format|
        format.html do
          flash[:notice] = 'Role has successfully been removed from Group'
          redirect_to admin_group_roles_path(@group)
        end
      end
    end

    private

    def load_group
      @group = Hyrax::Group.find_by(id: params[:group_id])
    end

    def redirect_not_found
      flash[:error] = 'Unable to find Group Role with that ID'
      redirect_to admin_group_roles_path(@group)
    end

    def cannot_remove_admin_role_from_admin_group
      role = Role.find_by(id: params[:role_id])
      return unless @group.name == ::Ability.admin_group_name && role.name == 'admin'

      redirect_back(
        fallback_location: edit_admin_group_path(@group),
        flash: { error: "Admin role cannot be removed from this group" }
      )
    end
  end
end
