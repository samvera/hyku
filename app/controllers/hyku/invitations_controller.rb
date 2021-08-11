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
      self.resource = User.find_by(email: params[:user][:email]) || invite_resource

      # Set roles, whether they are a new user or not
      # safe because adding the same role twice is a noop
      site = Site.instance
      if params[:user][:roles].present?
        params[:user][:roles].split(',').each do |role|
          resource.add_role(role.strip, site)
        end
      end
      # end of override code

      yield resource if block_given?

      # Override destination as this was a success either way
      if is_flashing_format? && resource.invitation_sent_at
        set_flash_message :notice, :send_instructions, email: resource.email
      end
      if method(:after_invite_path_for).arity == 1
        respond_with resource, location: after_invite_path_for(current_inviter)
      else
        respond_with resource, location: after_invite_path_for(current_inviter, resource)
      end
    end

    protected

      def user_params
        params.require(:user).permit(:email, :roles)
      end
  end
end
