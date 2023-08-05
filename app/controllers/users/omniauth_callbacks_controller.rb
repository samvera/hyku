module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController

    skip_before_action :verify_authenticity_token

    def callback
      # Here you will need to implement your logic for processing the callback
      # for example, finding or creating a user
      @user = User.from_omniauth(request.env['omniauth.auth'])

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: params[:provider]) if is_navigational_format?
      else
        session['devise.user_attributes'] = @user.attributes
        redirect_to new_user_registration_url
      end
    end
    alias_method :cas, :callback
    alias_method :openid_connect, :callback
    alias_method :saml, :callback
    alias_method :shibboleth, :callback

    def passthru
      render status: 404, plain: 'Not found. Authentication passthru.'
    end

    # def failure
    #   #redirect_to root_path
    # end
  end
end
