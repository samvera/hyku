# frozen_string_literal: true

module HyraxHelper
  include ::BlacklightHelper
  include Hyrax::BlacklightOverride
  include Hyrax::HyraxHelperBehavior

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
