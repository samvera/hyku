# frozen_string_literal: true
# OVERRIDE Hyraxv5.0.0 to add the ability to upload a collection thumbnail

Hyrax::Forms::PcdmCollectionForm.class_eval do
  include Hyrax::FormFields(:basic_metadata)
  include Hyrax::FormFields(:bulkrax_metadata)
  include CollectionAccessFiltering

  ThumbnailInfoPrepopulator = lambda do |_options = nil|
    self.thumbnail_info ||= begin
      thumbnail_info = CollectionBrandingInfo.where(collection_id: id.to_s, role: "thumbnail").first
      if thumbnail_info
        thumbnail_file = File.split(thumbnail_info.local_path).last
        alttext = thumbnail_info.alt_text
        file_location = thumbnail_info.local_path
        relative_path = "/" + thumbnail_info.local_path.split("/")[-4..-1].join("/")
        { file: thumbnail_file, full_path: file_location, relative_path:, alttext: }
      else
        {} # Always return at least an empty hash
      end
    end
  end

  property :thumbnail_info, virtual: true, prepopulator: ThumbnailInfoPrepopulator
end
