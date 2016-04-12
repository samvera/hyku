module SufiaHelper
  include ::BlacklightHelper
  include CurationConcerns::MainAppHelpers
  include Sufia::BlacklightOverride
  include Sufia::SufiaHelperBehavior

  def application_name
    Site.application_name || super
  end

  def institution_name
    Site.institution_name || super
  end

  alias institution_name_full institution_name
end
