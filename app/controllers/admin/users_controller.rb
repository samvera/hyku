# frozen_string_literal: true

module Admin
  class UsersController < AdminController
    before_action :load_user, only: [:destroy]

    # NOTE: User creation/invitations handled by devise_invitable

    # Delete a user from the site
    def destroy
      if @user.present? && @user.destroy
        redirect_to hyrax.admin_users_path, notice: t('hyrax.admin.users.destroy.success', user: @user)
      else
        redirect_to hyrax.admin_users_path flash: { error: t('hyrax.admin.users.destroy.failure', user: @user) }
      end
    end

    private

      def load_user
        @user = User.from_url_component(params[:id])
      end
  end
end
