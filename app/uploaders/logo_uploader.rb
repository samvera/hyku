# frozen_string_literal: true

class LogoUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include CarrierWave::Compatibility::Paperclip

  version :medium do
    process resize_to_fill: [300, 300]
  end

  version :thumb do
    process resize_to_fill: [100, 100]
  end

  def extension_whitelist
    %w[jpg jpeg png gif bmp tif tiff]
  end
end
