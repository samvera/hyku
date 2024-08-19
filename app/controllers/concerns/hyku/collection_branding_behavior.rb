# frozen_string_literal: true

module Hyku
  module CollectionBrandingBehavior
    # This is used for saving the CollectionBrandingInfo files to 'public/uploads' directory.
    #
    # Originally, when `f.file_url` is called, there's a string sub that happens in
    # CarrierWave that puts it into the 'uploads' dir instead.  We want it in the 'public/uploads' dir instead
    # @see https://github.com/carrierwaveuploader/carrierwave/blob/master/lib/carrierwave/uploader/url.rb#L24
    def process_file_location(f)
      if /^http/.match?(f.file_url)
        f.file.download!(f.file_url)
        f.file_url
      elsif %r{^\/}.match?(f.file_url)
        f.file.path
      else
        f.file_url
      end
    end
  end
end
