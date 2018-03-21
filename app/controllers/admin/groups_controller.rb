module Admin
  class GroupsController < AdminController
    before_action :load_group, only: %i[edit update remove destroy]

    # rubocop:disable Metrics/AbcSize
    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyku.admin.groups.title.index'), admin_groups_path
      @groups = Hyku::Group.search(params[:q]).page(page_number).per(page_size)
    end
    # rubocop:enable Metrics/AbcSize

    def new
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyku.admin.groups.title.new'), new_admin_group_path
      @group = Hyku::Group.new
    end

    def create
      new_group = Hyku::Group.new(group_params)
      if new_group.save
        redirect_to admin_groups_path, notice: t('hyku.admin.groups.flash.create.success', group: new_group.name)
      elsif new_group.invalid?
        redirect_to new_admin_group_path, alert: t('hyku.admin.groups.flash.create.invalid')
      else
        redirect_to new_admin_group_path, flash: { error: t('hyku.admin.groups.flash.create.failure') }
      end
    end

    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyku.admin.groups.title.edit'), edit_admin_group_path
    end

    def update
      if @group.update(group_params)
        redirect_to admin_groups_path, notice: t('hyku.admin.groups.flash.update.success', group: @group.name)
      else
        redirect_to edit_admin_group_path(@group), flash: {
          error: t('hyku.admin.groups.flash.update.failure', group: @group.name)
        }
      end
    end

    def remove
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyku.admin.groups.title.edit'), edit_admin_group_path
      add_breadcrumb t(:'hyku.admin.groups.title.remove'), request.path
    end

    def destroy
      if @group.destroy
        redirect_to admin_groups_path, notice: t('hyku.admin.groups.flash.destroy.success', group: @group.name)
      else
        logger.error("Hyku::Group id:#{@group.id} could not be destroyed")
        redirect_to admin_groups_path flash: { error: t('hyku.admin.groups.flash.destroy.failure', group: @group.name) }
      end
    end

    private

      def load_group
        @group = Hyku::Group.find_by(id: params[:id])
      end

      def group_params
        params.require(:hyku_group).permit(:name, :description)
      end

      def page_number
        params.fetch(:page, 1).to_i
      end

      def page_size
        params.fetch(:per, 10).to_i
      end
  end
end
