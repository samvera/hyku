class AuthProvidersController < ApplicationController
  layout 'hyrax/dashboard'

  before_action :ensure_admin!
  before_action :set_auth_provider, only: %i[edit update destroy]

  # GET /auth_providers/new
  def new
    add_breadcrumbs
    existing_auth_provider = AuthProvider.find(current_account.settings['auth_provider']) if current_account.settings['auth_provider']

    # users should not be able to reach the new auth provider page unless it is the first time they are setting up an auth provider.
    if existing_auth_provider
      redirect_to edit_auth_provider_url(existing_auth_provider)
    else
      @auth_provider = AuthProvider.new
    end
  end

  # GET /auth_providers/1/edit
  def edit
    add_breadcrumbs
  end

  # POST /auth_providers or /auth_providers.json
  def create
    @auth_provider = AuthProvider.new(auth_provider_params)
    respond_to do |format|
      if @auth_provider.save
        current_account.settings['auth_provider'] = @auth_provider.id
        current_account.save
        format.html { redirect_to edit_auth_provider_url(@auth_provider), notice: "Auth provider was successfully created." }
        format.json { render :show, status: :created, location: @auth_provider }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @auth_provider.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /auth_providers/1 or /auth_providers/1.json
  def update
    respond_to do |format|
      if @auth_provider.update(auth_provider_params)
        current_account.settings['auth_provider'] = @auth_provider.id
        current_account.save
        format.html { redirect_to edit_auth_provider_url(@auth_provider), notice: "Auth provider was successfully updated." }
        format.json { render :show, status: :ok, location: @auth_provider }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @auth_provider.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /auth_providers/1 or /auth_providers/1.json
  def destroy
    @auth_provider.destroy
    current_account.settings['auth_provider'] = nil
    current_account.save
    respond_to do |format|
      format.html { redirect_to new_auth_provider_url, notice: "Auth provider was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def add_breadcrumbs
    add_breadcrumb t(:'hyrax.controls.home'), root_path
    add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
    add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
    add_breadcrumb t(:'hyrax.admin.sidebar.auth_provider'), request.path
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_auth_provider
      @auth_provider = AuthProvider.find(params[:id])
    end

    def ensure_admin!
      authorize! :read, :admin_dashboard
    end

    # Only allow a list of trusted parameters through.
    def auth_provider_params
      params.require(:auth_provider).permit(
        :provider,
        :account_id,
        :saml_client_id,
        :saml_client_secret,
        :saml_idp_sso_service_url,
        :oidc_client_id,
        :oidc_client_secret,
        :oidc_idp_sso_service_url
      )
    end
end
