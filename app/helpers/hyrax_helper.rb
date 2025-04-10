# frozen_string_literal: true

module HyraxHelper
  include ::BlacklightHelper
  include Hyrax::BlacklightOverride
  include Hyrax::HyraxHelperBehavior
  include Hyku::BlacklightHelperBehavior

  # OVERRIDE Hyrax 5.0 to rescue from invalid dates w/o blowing up the page
  # A Blacklight helper_method
  # @param [Hash] options from blacklight invocation of helper_method
  # @see #index_field_link params
  # @return [Date]
  def human_readable_date(options)
    value = options[:value].first
    Date.parse(value).to_formatted_s(:standard)
  rescue
    value
  end

  def application_name
    Site.application_name || super
  end

  def institution_name
    Site.institution_name || super
  end

  def institution_name_full
    Site.institution_name_full || super
  end

  def banner_image
    Site.instance.banner_image? ? Site.instance.banner_image.url : super
  end

  def favicon(size)
    icon = Site.instance.favicon
    if icon
      case icon
      when FaviconUploader
        return Site.instance.favicon.url(size)
      when String
        return Site.instance.favicon
      end
    end
    nil
  end

  def logo_image
    Site.instance.logo_image? ? Site.instance.logo_image.url : false
  end

  def block_for(name:)
    ContentBlock.block_for(name:, fallback_value: false)
  end

  def directory_image
    Site.instance.directory_image? ? Site.instance.directory_image.url : false
  end

  def default_collction_image
    Site.instance.default_collection_image? ? Site.instance.default_collection_image.url : false
  end

  def default_work_image
    Site.instance.default_work_image? ? Site.instance.default_work_image.url : 'default.png'
  end

  # OVERRIDE: Add method to display a Hyrax::Group's human-readable name when the Hyrax::Group's
  # name is all that's available, e.g. when looking at a Hydra::AccessControl instance
  def display_hyrax_group_name(hyrax_group_name)
    label = I18n.t("hyku.admin.groups.humanized_name.#{hyrax_group_name}")
    return hyrax_group_name.titleize if label.include?('translation missing:')

    label
  end
end
