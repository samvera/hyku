# frozen_string_literal: true

class SitesController < ApplicationController
  before_action :set_site
  load_and_authorize_resource instance_variable: :site, class: 'Site' # descendents still auth Site
  layout 'hyrax/dashboard'

  def update
    # FIXME: Pull these strings out to i18n locale
    if @site.update(update_params)
      remove_appearance_text(update_params)
      redirect_to hyrax.admin_appearance_path, notice: 'The appearance was successfully updated.'
    else
      redirect_to hyrax.admin_appearance_path, flash: { error: 'Updating the appearance was unsuccessful.' }
    end

    @site.update(site_theme_params) if params[:site]
  end

  private

  def set_site
    @site ||= Site.instance
  end

  def update_params
    params.permit(:remove_banner_image,
                  :remove_favicon,
                  :remove_logo_image,
                  :remove_directory_image,
                  :remove_default_collection_image,
                  :remove_default_work_image)
  end

  def site_theme_params
    params.require(:site).permit(:home_theme, :search_theme, :show_theme)
  end

  REMOVE_TEXT_MAPS = {
    "remove_logo_image" => "logo_image_text",
    "remove_banner_image" => "banner_image_text",
    "remove_directory_image" => "directory_image_text",
    "remove_default_collection_image" => "default_collection_image_text",
    "remove_default_work_image" => "default_work_image_text"
  }.freeze

  def remove_appearance_text(update_params)
    image_text_keys = update_params.keys
    image_text_keys.each do |image_text_key|
      block = ContentBlock.find_by(name: REMOVE_TEXT_MAPS[image_text_key])
      block.delete if block&.value.present?
    end
  end
end
