module Hyrax
  class GenericWorksController < SharedBehaviorsController
    self.curation_concern_type = GenericWork

    include Hyku::IIIFManifest
  end
end
