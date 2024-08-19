# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token

    def callback
      logger.info("=@=@=@=@  auth: #{request.env['omniauth.auth']}, params: #{params.inspect}")
      # Here you will need to implement your logic for processing the callback
      # for example, finding or creating a user
      @user = User.from_omniauth(request.env['omniauth.auth'])

      if @user.persisted?
        # We need to render a loading page here just to set the sesion properly
        # otherwise the logged in session gets lost during the redirect
        if params[:action] == 'saml'
          set_flash_message(:notice, :success, kind: params[:action]) if is_navigational_format?
          sign_in @user, event: :authentication # this will throw if @user is not activated
          render 'complete'
        else
          sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
          set_flash_message(:notice, :success, kind: params[:action]) if is_navigational_format?
        end
      else
        session['devise.user_attributes'] = @user.attributes
        redirect_to new_user_registration_url
      end
    end
    alias cas callback
    alias openid_connect callback
    alias saml callback

    def passthru
      render status: :not_found, plain: 'Not found. Authentication passthru.'
    end

    def failure
      redirect_to root_path, flash: { error: 'Authentication Failed. Something is wrong with the SSO configuration.' }
    end
  end
end
