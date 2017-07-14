module Hyku
  class RegistrationsController < Devise::RegistrationsController
    def new
      return super if Settings.devise.account_signup
      redirect_to root_path, alert: t(:'hyku.account.signup_disabled')
    end

    def create
      return super if Settings.devise.account_signup
      redirect_to root_path, alert: t(:'hyku.account.signup_disabled')
    end
  end
end
