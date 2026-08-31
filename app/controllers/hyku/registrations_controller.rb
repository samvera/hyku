# frozen_string_literal: true

module Hyku
  class RegistrationsController < Devise::RegistrationsController
    include NegativeCaptchaBehavior

    SIGNUP_CAPTCHA_FIELDS = %i[display_name email password password_confirmation].freeze

    before_action :configure_permitted_parameters
    before_action :setup_signup_captcha, only: %i[new create], if: :signup_challenge_enabled?

    helper_method :signup_challenge_enabled?

    def new
      return super if current_account&.allow_signup
      redirect_to root_path, alert: t(:'hyku.account.signup_disabled')
    end

    def create
      return redirect_to root_path, alert: t(:'hyku.account.signup_disabled') unless current_account&.allow_signup

      if signup_challenge_enabled?
        return reject_signup_challenge unless @captcha.valid?
        params[:user] = @captcha.values
      end

      super
    end

    private

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:display_name])
    end

    def signup_challenge_enabled?
      return false unless current_account

      current_account.signup_spam_protection || current_account.public_demo_tenant?
    end

    def setup_signup_captcha
      @captcha = negative_captcha_for(SIGNUP_CAPTCHA_FIELDS)
    end

    def reject_signup_challenge
      redirect_to new_user_registration_path, alert: t(:'hyku.account.signup_challenge_failed')
    end
  end
end
