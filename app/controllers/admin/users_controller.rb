# frozen_string_literal: true

module Admin
  class UsersController < AdminController
    before_action :ensure_admin!, except: [:remove_role]
    # A public demo tenant publishes its admin login, so these stay with its superadmin
    before_action -> { authorize! :manage, :tenant_controls }, only: %i[destroy activate]
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
      # Users are shared across tenants, so only act on a pending user who belongs to this one
      user = User.for_repository.find(params[:id])
      # The lock makes a second concurrent click see the user as already active
      activated = user.with_lock { user.invited_to_sign_up? && accept_invitation_for(user) }

      if activated
        send_activation_instructions(user)
        redirect_to hyrax.admin_users_path, notice: t('hyrax.admin.users.activate.success', user:)
      else
        redirect_to hyrax.admin_users_path, flash: { error: t('hyrax.admin.users.activate.failure', user:) }
      end
    end

    def remove_role
      user = User.find(params[:id])
      authorize! :edit, user
      role = Role.find(params[:role_id])
      authorize! :grant_admin_role, user if role.name.in?(%w[admin superadmin])

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

    # Assign the operator-configured default password when one is provided;
    # otherwise assign a random placeholder so activation never falls back
    # to a well-known literal.
    def accept_invitation_for(user)
      user.password = ENV.fetch('HYKU_USER_DEFAULT_PASSWORD', nil).presence || Devise.friendly_token[0, 20]
      user.save && user.accept_invitation!
    end

    # Activation consumes the invitation and assigns a password the user does not know,
    # so email them a link to set their own. Devise's stock reset email tells the
    # recipient to ignore it if they did not ask for it, hence the dedicated template.
    def send_activation_instructions(user)
      token = user.send(:set_reset_password_token)
      user.send(:send_devise_notification, :reset_password_instructions, token,
                template_name: 'activation_instructions',
                subject: t('devise.mailer.activation_instructions.subject'))
    end
  end
end
