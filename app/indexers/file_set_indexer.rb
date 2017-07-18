class FileSetIndexer < Hyrax::FileSetIndexer
  self.thumbnail_path_service = IIIFWorkThumbnailPathService
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['hasRendering_ssim'] = object.rendering_ids
    end
  end
end
