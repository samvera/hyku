class SitesController < ApplicationController
  before_action :set_site
  load_and_authorize_resource instance_variable: :site, class: 'Site' # descendents still auth Site
  layout 'hyrax/dashboard'

  def update
    # FIXME: Pull these strings out to i18n locale
    if @site.update(update_params)
      redirect_to hyrax.admin_appearance_path, notice: 'The appearance was successfully updated.'
    else
      redirect_to hyrax.admin_appearance_path, flash: { error: 'Updating the appearance was unsuccessful.' }
    end
  end

  private

    def set_site
      @site ||= Site.instance
    end

    def update_params
      params.permit(:remove_banner_image,
                    :remove_logo_image,
                    :remove_directory_image,
                    :remove_default_collection_image,
                    :remove_default_work_image)
    end
end
