# frozen_string_literal: true

# OVERRIDE Hyrax::AvatarUploader to rename uploaded avatar files.
# Version blocks must override filename so medium/thumb versions use the parent's
# tenant-scoped filename instead of the original filename.
module Hyku
  class AvatarUploader < Hyrax::AvatarUploader
    include Hyku::FileRenameable

    version :medium do
      process resize_to_limit: [300, 300]

      # @return [String, nil] The parent uploader's filename when present, so this version
      #   uses the same tenant-scoped name; otherwise delegates to super.
      def filename
        parent_version.present? ? parent_version.filename : super
      end
    end

    version :thumb do
      process resize_to_limit: [100, 100]

      # @return [String, nil] The parent uploader's filename when present, so this version
      #   uses the same tenant-scoped name; otherwise delegates to super.
      def filename
        parent_version.present? ? parent_version.filename : super
      end
    end
  end
end
