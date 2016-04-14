class SitesController < ApplicationController
  before_action :set_site
  load_and_authorize_resource

  # GET /sites/1/edit
  def edit
  end

  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
    respond_to do |format|
      if @site.update(site_params)
        format.html { redirect_to edit_site_path, notice: 'Site was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  private

    def set_site
      @site ||= Site.instance
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def site_params
      params.require(:site).permit(:application_name, :institution_name, :institution_name_full)
    end
end
