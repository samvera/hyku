# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, prepend: true

  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior

  # Adds Hyrax behaviors into the application controller
  include Hyrax::Controller

  include Hyrax::ThemedLayoutController
  with_themed_layout '1_column'

  include HykuHelper
  include DeviseGuestControllersHelpersDecorator

  helper_method :current_account, :admin_host?, :home_page_theme, :show_page_theme, :search_results_theme
  before_action :authenticate_if_needed
  before_action :require_active_account!, if: :multitenant?
  before_action :set_account_specific_connections!
  before_action :elevate_single_tenant!, if: :singletenant?

  after_action :clear_session_cookie

  rescue_from Apartment::TenantNotFound do
    raise ActionController::RoutingError, 'Not Found'
  end

  protected

  def clear_session_cookie
    return if current_user || !cached_route?(request.path)

    return unless response.headers["Cache-Control"].blank? || !(response.headers["Cache-Control"].include?('no-store') || response.headers["Cache-Control"].include?('no-cache'))
    # this skips sending a session cookie # (a session cookie will cause cloudflare to avoid caching it)
    request.session_options[:skip] = true
  end

  def cached_route?(path)
    path.start_with?('/concern', '/catalog')
  end

  def hidden?
    current_account.persisted? && !current_account.is_public?
  end

  def api_or_pdf?
    request.format.to_s.match('json') ||
      params[:print] ||
      request.path.include?('api') ||
      request.path.include?('pdf')
  end

  def staging?
    Rails.env.staging? # rubocop:disable Rails/UnknownEnv
  end

  ##
  # @!attribute http_basic_auth_username [r|w]
  #   @return [String]
  #   @see ApplicationController#authenticate_if_needed
  class_attribute :http_basic_auth_username, default: 'samvera'

  ##
  # @!attribute http_basic_auth_password [r|w]
  #   @return [String]
  #   @see ApplicationController#authenticate_if_needed
  class_attribute :http_basic_auth_password, default: 'hyku'

  def authenticate_if_needed
    # Disable this extra authentication in test mode
    return true if Rails.env.test?
    return unless (hidden? || staging?) && !api_or_pdf?
    authenticate_or_request_with_http_basic do |username, password|
      username == http_basic_auth_username && password == http_basic_auth_password
    end
  end

  def super_and_current_users
    users = Role.find_by(name: 'superadmin')&.users.to_a
    users << current_user if current_user && !users.include?(current_user)
    users
  end

  # Override method from devise-guests v0.8.2 to prevent the application from
  # attempting to create duplicate guest users; namely by adding the
  # User.unscoped
  def guest_user
    return @guest_user if @guest_user
    if session[:guest_user_id]
      # Override - added #unscoped to include guest users who are filtered out of User queries by default
      @guest_user = begin
                      User.unscoped.find_by(User.authentication_keys.first => session[:guest_user_id])
                    rescue
                      nil
                    end
      @guest_user = nil if @guest_user.respond_to?(:guest) && !@guest_user.guest
    end
    @guest_user ||= begin
                      u = create_guest_user(session[:guest_user_id])
                      session[:guest_user_id] = u.send(User.authentication_keys.first)
                      u
                    end
    @guest_user
  end

  private

  def require_active_account!
    return if singletenant?
    return if devise_controller?
    raise Apartment::TenantNotFound, "No tenant for #{request.host}" unless current_account.persisted?
  end

  def set_account_specific_connections!
    current_account&.switch!
  end

  def multitenant?
    @multitenant ||= ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_MULTITENANT', false))
  end

  def singletenant?
    !multitenant?
  end

  def elevate_single_tenant!
    AccountElevator.switch!(current_account.cname) if current_account && root_host?
  end

  def root_host?
    Account.canonical_cname(request.host) == Account.root_host
  end

  def admin_host?
    return false if singletenant?
    Account.canonical_cname(request.host) == Account.admin_host
  end

  def current_account
    @current_account ||= Account.from_request(request)
    @current_account ||= if multitenant?
                           Account.new do |a|
                             a.build_solr_endpoint
                             a.build_fcrepo_endpoint
                             a.build_redis_endpoint
                           end
                         else
                           Account.single_tenant_default
                         end
  end

  # Find themes set on Site model, or return default
  def home_page_theme
    current_account.sites&.first&.home_theme || 'default_home'
  end

  def show_page_theme
    current_account.sites&.first&.show_theme || 'default_show'
  end

  def search_results_theme
    current_account.sites&.first&.search_theme || 'list_view'
  end

  # Add context information to the lograge entries
  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.uuid
    payload[:user_id] = current_user.id if current_user
    payload[:account_id] = current_account.cname if current_account
  end
end
# rubocop:enable Metrics/ClassLength
