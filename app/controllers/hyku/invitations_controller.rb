# frozen_string_literal: true

module Hyku
  class InvitationsController < Devise::InvitationsController
    # For devise_invitable, specify post-invite path to be 'Manage Users' form
    # (as the user invitation form is also on that page)
    def after_invite_path_for(_resource)
      hyrax.admin_users_path
    end

    # override the standard invite so that accounts are added properly
    # if they already exist on another tenant and invited if they do not
    def create
      respond_to do |format|
        if current_account.update(account_params)
          format.html { redirect_to hyrax.admin_users_path, notice: 'Account was successfully updated.' }
        else
          format.html { redirect_to hyrax.admin_users_path, notice: 'Account could not be added.' }
        end
      end
    end

    protected

      def account_params
        params.require(:account).permit(admin_emails: [])
      end
  end
end
