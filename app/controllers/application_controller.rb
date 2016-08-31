class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, prepend: true

  force_ssl if: :ssl_configured?

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

  helper_method :peek_enabled?

  before_action :require_active_account!, if: :multitenant?
  before_action :set_account_specific_connections!

  before_action :add_honeybadger_context

  rescue_from Apartment::TenantNotFound do
    raise ActionController::RoutingError, 'Not Found' unless worker? || base_host?
    redirect_to splash_path
  end

  private

    def peek_enabled?
      can? :peek, Lerna::Application
    end

    def require_active_account!
      return if devise_controller? || peek_controller?

      raise Apartment::TenantNotFound, "No tenant for #{request.host}" unless current_account
    end

    def set_account_specific_connections!
      current_account.switch! if current_account
    end

    def worker?
      # Cast because although YAML supports boolean types, ENV variables don't
      ActiveRecord::Type::Boolean.new.cast(Settings.worker)
    end

    def multitenant?
      Settings.multitenancy.enabled
    end

    def base_host?
      Account.canonical_cname(request.host) == Account.canonical_cname(Settings.multitenancy.host)
    end

    def current_account
      @current_account ||= Account.from_request(request)
    end

    # Add context information to the lograge entries
    def append_info_to_payload(payload)
      super
      payload[:request_id] = request.uuid
      payload[:user_id] = current_user.id if current_user
      payload[:account_id] = current_account.cname if current_account
    end

    def add_honeybadger_context
      Honeybadger.context(user_email: current_user.email) if current_user
    end

    def ssl_configured?
      ActiveRecord::Type::Boolean.new.cast(Settings.ssl_configured)
    end

    def peek_controller?
      is_a? Peek::ResultsController
    end
end
