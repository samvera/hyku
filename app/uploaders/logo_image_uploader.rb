class LogoImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  process resize_to_limit: [100, 50]

  def store_dir
    'public/uploads/logo_images'
  end

  # Define valid extensions for site banner image
  def extension_white_list
    %w[jpg jpeg png gif]
  end
end
