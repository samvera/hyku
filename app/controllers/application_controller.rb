class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior

  # Adds CurationConcerns behaviors to the application controller.
  include CurationConcerns::ApplicationControllerBehavior
  # Adds Sufia behaviors into the application controller
  include Sufia::Controller

  include CurationConcerns::ThemedLayoutController
  layout 'sufia-one-column'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :require_active_account!, if: :multitenant?

  rescue_from Apartment::TenantNotFound do
    redirect_to accounts_path
  end

  private

    def require_active_account!
      account = Account.from_request(request)

      raise Apartment::TenantNotFound, "No tenant for #{request.host}" unless account
    end

    def multitenant?
      Settings.multitenant
    end
end
