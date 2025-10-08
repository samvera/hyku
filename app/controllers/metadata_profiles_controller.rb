# frozen_string_literal: true

class MetadataProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  def index
    @metadata_profiles = []
  end

  def show
    # Basic implementation for testing
    head :ok
  end

  def new
    # Basic implementation for testing
    head :ok
  end

  def edit
    # Basic implementation for testing
    head :ok
  end

  private

  def ensure_admin!
    authorize! :read, :admin_dashboard
  end
end