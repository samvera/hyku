module Hyrax
  class ImagesController < SharedBehaviorsController
    self.curation_concern_type = ::Image

    # Use this line if you want to use a custom presenter
    # self.show_presenter = Hyrax::ImagePresenter

    # Instead we include IIIFManifest which uses the manifest-enabled show
    # presenter
    include Hyku::IIIFManifest
  end
end
