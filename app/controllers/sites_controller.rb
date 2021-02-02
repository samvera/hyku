# frozen_string_literal: true

class SitesController < ApplicationController
  before_action :set_site
  load_and_authorize_resource instance_variable: :site, class: 'Site' # descendents still auth Site
  layout 'hyrax/dashboard'

  def update
    if params[:site]
      @site.update(site_theme_params)
    end
    
    # FIXME: Pull these strings out to i18n locale

    # Dynamic CarrierWave methods
    remove_image_methods = %i[remove_banner_image
                              remove_logo_image
                              remove_directory_image
                              remove_default_collection_image
                              remove_default_work_image]

    # JUST removes images from file system, does not update @site attrs
    remove_image_methods.each do |key|
      @site.send("#{key}!") if params[key]
    end

    @site.save

    if params['remove_default_collection_image']
      # Reindex all Collections and AdminSets to fall back on Hyrax's default collection image
      ReindexCollectionsJob.perform_later
      ReindexAdminSetsJob.perform_later
    elsif params['remove_default_work_image']
      # Reindex all Works to fall back on Hyrax's default work image
      ReindexWorksJob.perform_later
    end

    redirect_to hyrax.admin_appearance_path, notice: 'The appearance was successfully updated.'
  end

  private

    def set_site
      @site ||= Site.instance
    end

    def site_theme_params
      params.require(:site).permit(:home_theme, :search_theme, :show_theme)
    end
end
