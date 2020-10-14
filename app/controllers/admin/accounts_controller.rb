# frozen_string_literal: true

module Admin
  class AccountsController < AdminController
    before_action :set_current_account
    load_and_authorize_resource

    # GET /accounts/1/edit
    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb @account.tenant, edit_admin_account_path
    end

    # PATCH/PUT /accounts/1
    # PATCH/PUT /accounts/1.json
    def update
      respond_to do |format|
        if @account.update(account_params)
          format.html { redirect_to edit_admin_account_path, notice: 'Account was successfully updated.' }
          format.json { render :show, status: :ok, location: root_url }
        else
          format.html { render :edit }
          format.json { render json: @account.errors, status: :unprocessable_entity }
        end
      end
    end

    private

      def account_params
        params.require(:account).permit(:name, :cname, :title)
      end

      def set_current_account
        @account = Site.account
      end
  end
end
