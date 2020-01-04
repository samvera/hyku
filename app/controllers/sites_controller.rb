class SitesController < ApplicationController
  before_action :set_site
  load_and_authorize_resource instance_variable: :site, class: 'Site' # descendents still auth Site
  layout 'hyrax/dashboard'

  def update
    # params.permit([:remove_banner_image, :remove_logo_image])
    %i[remove_banner_image
       remove_logo_image
       remove_directory_image
       remove_default_collection_image
       remove_default_work_image].each do |key|
      @site.send("#{key}!") if params[key]
    end

    redirect_to hyrax.admin_appearance_path, notice: 'The appearance was successfully updated.'
  end

  private

    def set_site
      @site ||= Site.instance
    end
end
