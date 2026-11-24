# frozen_string_literal: true

module Hyku
  class InvitationsController < Devise::InvitationsController
    # devise_invitable's own filter only authenticates the inviter, so without
    # this any signed-in user could invite. Who may invite is decided entirely
    # in the ability layer.
    # @see Hyrax::Ability::UserAbility
    # @see Hyrax::Ability::TenantControlAbility
    before_action -> { authorize! :invite, User }, only: :create

    # For devise_invitable, specify post-invite path to be 'Manage Users' form
    # (as the user invitation form is also on that page)
    def after_invite_path_for(_resource)
      hyrax.admin_users_path
    end

    # override the standard invite so that accounts are added properly
    # if they already exist on another tenant and invited if they do not
    # rubocop:disable Metrics/AbcSize
    def create
      authorize! :grant_admin_role, User if params[:user][:role] == ::RolesService::ADMIN_ROLE
      existing_user = User.find_by(email: params[:user][:email])
      self.resource = existing_user || invite_resource

      resource.add_default_group_membership!
      resource.add_role(params[:user][:role], Site.instance) if params[:user][:role].present?
      resend_invitation(existing_user) if existing_user

      yield resource if block_given?

      # Override destination as this was a success either way
      flash_invite_result(existing_user) if is_flashing_format?
      if method(:after_invite_path_for).arity == 1
        respond_with resource, location: after_invite_path_for(current_inviter)
      else
        respond_with resource, location: after_invite_path_for(current_inviter, resource)
      end
    end
    # rubocop:enable Metrics/AbcSize

    protected

    # Inviting a user who has not accepted yet resends their invitation, as the invite form says it does.
    # Reloaded so an Activate that finished after the lookup is respected.
    def resend_invitation(user)
      user.invite!(current_inviter) if user.reload.invited_to_sign_up?
    end

    # An existing active user is only added to this repository, so say that instead of "invitation sent"
    def flash_invite_result(existing_user)
      if existing_user && !existing_user.invited_to_sign_up?
        set_flash_message :notice, :added_existing_user, email: resource.email
      elsif resource.invitation_sent_at
        set_flash_message :notice, :send_instructions, email: resource.email
      end
    end

    def user_params
      params.require(:user).permit(:email, :role)
    end
  end
end
