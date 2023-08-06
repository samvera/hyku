# frozen_string_literal: true

class SingleSignonController < DeviseController
  def index
    @identity_providers = IdentityProvider.all
    if @identity_providers.count.zero?
      redirect_to main_app.new_user_session_path
      return
    end
  end
end
