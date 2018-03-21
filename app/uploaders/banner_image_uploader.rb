class BannerImageUploader < CarrierWave::Uploader::Base
  # Define valid extensions for site banner image
  def extension_white_list
    %w[jpg jpeg png gif]
  end
end
