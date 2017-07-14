class FileSetIndexer < Hyrax::FileSetIndexer
  self.thumbnail_path_service = IIIFWorkThumbnailPathService
end
