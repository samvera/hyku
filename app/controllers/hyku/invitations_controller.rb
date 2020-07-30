# frozen_string_literal: true

module Hyku
  class InvitationsController < Devise::InvitationsController
    # For devise_invitable, specify post-invite path to be 'Manage Users' form
    # (as the user invitation form is also on that page)
    def after_invite_path_for(_resource)
      hyrax.admin_users_path
    end
  end
end
