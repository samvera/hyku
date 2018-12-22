class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  version :medium do
    process resize_to_limit: [300, 300]
  end

  version :thumb do
    process resize_to_limit: [100, 100]
  end

  def extension_whitelist
    %w[jpg jpeg png gif bmp tif tiff]
  end

  def store_dir
    configured_upload_path + "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def cache_dir
    configured_cache_path + "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  private

  def configured_upload_path
    Hyrax.config.upload_path.call
  end

  def configured_cache_path
    Hyrax.config.cache_path.call
  end
end
