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

  def default_collection_image
    Site.instance.default_collection_image? ? Site.instance.default_collection_image.url : super
  end
end
