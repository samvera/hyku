# frozen_string_literal: true

module Admin
  class UsersController < AdminController
    before_action :ensure_admin!, except: [:remove_role]
    before_action :load_user, only: [:destroy]

    # NOTE: User creation/invitations handled by devise_invitable

    # Delete a user from the site
    def destroy
      if @user.present? && @user.roles.destroy_all
        redirect_to hyrax.admin_users_path, notice: t('hyrax.admin.users.destroy.success', user: @user)
      else
        redirect_to hyrax.admin_users_path, flash: { error: t('hyrax.admin.users.destroy.failure', user: @user) }
      end
    end

    def activate
      user = User.find(params[:id])
      # Assign the operator-configured default password when one is provided;
      # otherwise assign a random placeholder so activation never falls back
      # to a well-known literal. Users who do not know the placeholder can set
      # their own password through the password reset flow.
      user.password = ENV.fetch('HYKU_USER_DEFAULT_PASSWORD', nil).presence || Devise.friendly_token[0, 20]

      if user.save && user.accept_invitation!
        redirect_to hyrax.admin_users_path, notice: t('hyrax.admin.users.activate.success', user:)
      else
        redirect_to hyrax.admin_users_path, flash: { error: t('hyrax.admin.users.activate.failure', user:) }
      end
    end

    def remove_role
      authorize! :edit, User

      user = User.find(params[:id])
      role = Role.find(params[:role_id])

      if user && role && user.roles.include?(role)
        user.remove_role(role.name)
        flash[:notice] = "Role '#{role.name}' was successfully removed from user #{user.email}."
      else
        flash[:alert] = "Failed to remove role from user #{user.email}."
      end

      redirect_back(fallback_location: root_path)
    end

    private

    def load_user
      @user = User.from_url_component(params[:id])
    end
  end
end
