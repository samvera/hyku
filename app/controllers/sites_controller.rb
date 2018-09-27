class SitesController < ApplicationController
  before_action :set_site
  load_and_authorize_resource instance_variable: :site, class: 'Site' # descendents still auth Site
  layout 'hyrax/dashboard'

  def update
    # params.permit([:remove_banner_image, :remove_logo_image])

    @site.remove_banner_image! if params[:remove_banner_image]
    @site.remove_logo_image! if params[:remove_logo_image]
    @site.remove_default_collection_image! if params[:remove_default_collection_image]
    @site.remove_default_work_image! if params[:remove_default_work_image]

    redirect_to hyrax.admin_appearance_path, notice: 'The appearance was successfully updated.'
  end

  private

    def set_site
      @site ||= Site.instance
    end
end
