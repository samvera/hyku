# frozen_string_literal: true

module Admin
  class GroupUsersController < ApplicationController
    before_action :load_group
    before_action :cannot_remove_admin_users_from_admin_group, only: [:destroy]
    layout 'hyrax/dashboard'

    def index
      authorize! :edit, Hyrax::Group
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyku.admin.groups.title.edit'), edit_admin_group_path(@group)
      add_breadcrumb t(:'hyku.admin.groups.title.members'), request.path
      @users = @group.search_members(params[:q]).page(page_number).per(page_size)
      render template: 'admin/groups/users'
    end

    def create
      @group.add_members_by_id(params[:user_id])
      respond_to do |format|
        format.html { redirect_to admin_group_users_path(@group) }
      end
    end

    def destroy
      @group.remove_members_by_id(params[:user_id])
      respond_to do |format|
        format.html { redirect_to admin_group_users_path(@group) }
      end
    end

    private

    def load_group
      @group = Hyrax::Group.find_by(id: params[:group_id])
    end

    def page_number
      params.fetch(:page, 1).to_i
    end

    def page_size
      params.fetch(:per, 10).to_i
    end

    def cannot_remove_admin_users_from_admin_group
      return unless @group.name == ::Ability.admin_group_name

      redirect_back(
        fallback_location: edit_admin_group_path(@group),
        flash: { error: "Admin users cannot be removed from this group" }
      )
    end
  end
end
