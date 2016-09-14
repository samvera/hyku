class ContentBlocksController < ApplicationController
  before_action :set_site
  load_and_authorize_resource instance_variable: :site, class: 'Site'
  layout 'admin'

  # GET /sites/1/edit
  def edit
    add_breadcrumb t(:'sufia.controls.home'), root_path
    add_breadcrumb t(:'sufia.toolbar.admin.menu'), sufia.admin_path
    add_breadcrumb t(:'sufia.admin.sidebar.content_blocks'), edit_site_content_blocks_path
  end

  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
    respond_to do |format|
      if @site.update_content(site_params)
        format.html { redirect_to edit_site_content_blocks_path, notice: 'Site was successfully updated.' }
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
      params.require(:site).permit(:announcement_text,
                                   :marketing_text,
                                   :featured_researcher,
                                   :about_page)
    end
end
