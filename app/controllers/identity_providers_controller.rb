# frozen_string_literal: true

class IdentityProvidersController < ApplicationController
  layout 'hyrax/dashboard'

  before_action :ensure_admin!
  before_action :set_identity_provider, only: %i[edit update destroy]
  before_action :set_provider_collection, only: %i[new edit create update]

  def index
    add_breadcrumbs
    @identity_providers = IdentityProvider.all
  end

  # GET /identity_providers/new
  def new
    add_breadcrumbs
    @identity_provider = IdentityProvider.new
  end

  # GET /identity_providers/1/edit
  def edit
    add_breadcrumbs
  end

  # POST /identity_providers or /identity_providers.json
  def create
    @identity_provider = IdentityProvider.new(identity_provider_params)
    respond_to do |format|
      if @identity_provider.save
        format.html do
          redirect_to edit_identity_provider_url(@identity_provider),
                      notice: "Auth provider was successfully created."
        end
        format.json { render :show, status: :created, location: @identity_provider }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @identity_provider.errors, status: :unprocessable_entity }
      end
    end
  rescue JSON::ParserError => e
    @identity_provider.add_error(:options, "Invalid JSON #{e.message}")
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @identity_provider.errors, status: :unprocessable_entity }
    end
  end

  # PATCH/PUT /identity_providers/1 or /identity_providers/1.json
  def update
    respond_to do |format|
      if @identity_provider.update(identity_provider_params)
        format.html do
          redirect_to edit_identity_provider_url(@identity_provider),
                      notice: "Auth provider was successfully updated."
        end
        format.json { render :show, status: :ok, location: @identity_provider }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @identity_provider.errors, status: :unprocessable_entity }
      end
    end
  rescue JSON::ParserError => e
    @identity_provider.add_error(:options, "Invalid JSON #{e.message}")
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @identity_provider.errors, status: :unprocessable_entity }
    end
  end

  # DELETE /identity_providers/1 or /identity_providers/1.json
  def destroy
    @identity_provider.destroy
    respond_to do |format|
      format.html { redirect_to new_identity_provider_url, notice: "Auth provider was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def add_breadcrumbs
    add_breadcrumb t(:'hyrax.controls.home'), root_path
    add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
    add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
    add_breadcrumb t(:'hyrax.admin.sidebar.identity_provider'), request.path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_identity_provider
    @identity_provider = IdentityProvider.find(params[:id])
  end

  def set_provider_collection
    @provider_collection = Devise.omniauth_providers.map { |o| [o, o.upcase] }
  end

  def ensure_admin!
    authorize! :read, :admin_dashboard
  end

  # Only allow a list of trusted parameters through.
  def identity_provider_params
    return @identity_provider_params if @identity_provider_params
    @identity_provider_params = params.require(:identity_provider).permit(
      :name,
      :provider,
      :options,
      :logo_image,
      :logo_image_text
    )
    @identity_provider_params['options'].presence &&
      @identity_provider_params['options'] = JSON.parse(@identity_provider_params['options'])
    @identity_provider_params
  end
end
