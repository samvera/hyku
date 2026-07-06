# frozen_string_literal: true

module Hyku
  # Handles user self-registration, honoring the per-tenant allow_signup
  # setting and an optional in-app spam challenge: a honeypot field that must
  # remain blank plus a minimum time between rendering and submitting the
  # form. The challenge is controlled by the signup_spam_protection account
  # setting and is always enforced on public demo tenants.
  class RegistrationsController < Devise::RegistrationsController
    HONEYPOT_FIELD = :registration_website
    TIMESTAMP_FIELD = :registration_timestamp
    MINIMUM_SUBMIT_SECONDS = 4

    before_action :configure_permitted_parameters

    helper_method :signup_challenge_enabled?, :signup_challenge_timestamp

    def new
      return super if current_account&.allow_signup
      redirect_to root_path, alert: t(:'hyku.account.signup_disabled')
    end

    def create
      return redirect_to root_path, alert: t(:'hyku.account.signup_disabled') unless current_account&.allow_signup
      return reject_signup_challenge unless signup_challenge_passed?

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

    # A signed timestamp embedded in the registration form so #create can
    # verify how long ago the form was rendered.
    def signup_challenge_timestamp
      signup_challenge_verifier.generate(Time.current.to_i)
    end

    def signup_challenge_passed?
      return true unless signup_challenge_enabled?

      params[HONEYPOT_FIELD].blank? && minimum_submission_time_elapsed?
    end

    def minimum_submission_time_elapsed?
      issued_at = signup_challenge_verifier.verify(params[TIMESTAMP_FIELD].to_s)
      (Time.current.to_i - issued_at) >= MINIMUM_SUBMIT_SECONDS
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      false
    end

    def signup_challenge_verifier
      Rails.application.message_verifier('hyku_signup_challenge')
    end

    def reject_signup_challenge
      redirect_to new_user_registration_path, alert: t(:'hyku.account.signup_challenge_failed')
    end
  end
end
