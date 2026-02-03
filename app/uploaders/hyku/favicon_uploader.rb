# frozen_string_literal: true

module Hyku
  class FaviconUploader < Hyrax::AvatarUploader
    include Hyku::FileRenameable
    # rubocop:disable Style/AsciiComments
    # 32×32	favicon-32.png	Standard for most desktop browsers
    # 128×128	favicon-128.png	Chrome Web Store icon & Small Windows 8 Star Screen Icon*
    # 152×152	favicon-152.png	iPad touch icon (Change for iOS 7: up from 144×144)
    # 167×167	favicon-167.png	iPad Retina touch icon
    # 180×180	favicon-180.png	iPhone Retina
    # 192×192	favicon-192.png	Google Developer Web App Manifest Recommendation
    # 196×196	favicon-196.png Chrome for Android home screen icon
    # rubocop:enable Style/AsciiComments

    versions.delete(:medium)
    versions.delete(:thumb)

    [32, 57, 76, 96, 128, 192, 228, 196, 120, 152, 180].each do |i|
      version "v#{i}".to_sym do
        process resize_to_limit: [i, i]

        # @return [String, nil] The parent uploader's filename when present, so this version
        #   uses the same tenant-scoped name; otherwise delegates to super.
        def filename
          parent_version.present? ? parent_version.filename : super
        end
      end
    end

    # @return [Array<String>] Allowed extensions for favicon uploads (png and ico).
    def extension_whitelist
      %w[png ico]
    end
  end
end
