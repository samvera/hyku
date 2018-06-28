class SitesController < ApplicationController
  before_action :set_site
  load_and_authorize_resource instance_variable: :site, class: 'Site' # descendents still auth Site
  layout 'hyrax/dashboard'

  def update
    params.require(:remove_banner_image)
    @site.remove_banner_image!
    redirect_to hyrax.admin_appearance_path, notice: 'The appearance was successfully updated.'
  end

  private

    def set_site
      @site ||= Site.instance
    end
end
