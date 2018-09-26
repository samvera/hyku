class DefaultWorkImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  # process resize_to_limit: [100, 50]

  # Define valid extensions for site banner image
  def extension_white_list
    %w[jpg jpeg png gif]
  end
end
