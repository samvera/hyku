# frozen_string_literal: true

module Admin
  module AccountsControllerDecorator
    def account_params
      params.require(:account).permit(:name, :cname, :title,
                                      *@account.public_settings(
                                        # OVERRIDE passing is_superadmin
                                        is_superadmin: current_user.superadmin?
                                      ).keys)
    end
  end
end

Admin::AccountsController.prepend(Admin::AccountsControllerDecorator)
