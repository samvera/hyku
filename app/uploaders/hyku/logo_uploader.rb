# frozen_string_literal: true

module Hyku
  class LogoUploader < Hyrax::AvatarUploader
    include Hyku::FileRenameable

    version :medium do
      process resize_to_fill: [300, 300]

      # @return [String, nil] The parent uploader's filename when present, so this version
      #   uses the same tenant-scoped name; otherwise delegates to super.
      def filename
        parent_version.present? ? parent_version.filename : super
      end
    end

    version :thumb do
      process resize_to_fill: [100, 100]

      # @return [String, nil] The parent uploader's filename when present, so this version
      #   uses the same tenant-scoped name; otherwise delegates to super.
      def filename
        parent_version.present? ? parent_version.filename : super
      end
    end

    # @return [Array<String>] Allowed image extensions for logo uploads.
    def extension_whitelist
      %w[jpg jpeg png gif bmp tif tiff]
    end
  end
end
