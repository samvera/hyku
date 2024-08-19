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
    # rubocop:disable Metrics/AbcSize
    def create
      authorize! :grant_admin_role, User if params[:user][:role] == ::RolesService::ADMIN_ROLE
      self.resource = User.find_by(email: params[:user][:email]) || invite_resource

      resource.add_default_group_membership!
      resource.add_role(params[:user][:role], Site.instance) if params[:user][:role].present?

      yield resource if block_given?

      # Override destination as this was a success either way
      set_flash_message :notice, :send_instructions, email: resource.email if is_flashing_format? && resource.invitation_sent_at
      if method(:after_invite_path_for).arity == 1
        respond_with resource, location: after_invite_path_for(current_inviter)
      else
        respond_with resource, location: after_invite_path_for(current_inviter, resource)
      end
    end
    # rubocop:enable Metrics/AbcSize

    protected

    def user_params
      params.require(:user).permit(:email, :role)
    end
  end
end
