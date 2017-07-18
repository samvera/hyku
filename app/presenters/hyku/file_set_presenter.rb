module Hyku
  class FileSetPresenter < Hyrax::FileSetPresenter
    include DisplaysImage
    # CurationConcern methods
    delegate :rendering_ids, :to_s, to: :solr_document
  end
end
