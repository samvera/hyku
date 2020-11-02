# frozen_string_literal: true

module Admin
  class GroupRolesController < AdminController
    before_action :load_group

    rescue_from ActiveRecord::RecordNotFound, with: :redirect_not_found

    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyku.admin.groups.title.edit'), edit_admin_group_path(@group)
      add_breadcrumb t(:'hyku.admin.groups.title.roles'), request.path

      @roles = ::Role.site - @group.roles
      render template: 'admin/groups/roles'
    end

    def add
      role = ::Role.find(params[:role_id])
      @group.roles << role unless @group.roles.include?(role)

      respond_to do |format|
        format.html do
          flash[:notice] = 'Role has successfully been added to Group'
          redirect_to admin_group_roles_path(@group)
        end
      end
    end

    def remove
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
  end
end
