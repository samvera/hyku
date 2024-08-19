# frozen_string_literal: true

class LabelsController < SitesController
  # GET /sites/1/edit
  def edit
    add_breadcrumb t(:'hyrax.controls.home'), root_path
    add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
    add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
    add_breadcrumb t(:'hyrax.admin.sidebar.labels'), edit_site_labels_path
  end

  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
    respond_to do |format|
      if @site.update(site_params)
        format.html { redirect_to edit_site_labels_path, notice: 'Labels were successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the permitted parameters through.
  def site_params
    params.require(:site).permit(:application_name,
                                 :institution_name,
                                 :institution_name_full)
  end
end
