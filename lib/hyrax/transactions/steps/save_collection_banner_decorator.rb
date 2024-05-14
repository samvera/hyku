# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0 to save the collection banner in 'public/uploads'

module Hyrax
  module Transactions
    module Steps
      module SaveCollectionBannerDecorator
        include Hyku::CollectionBrandingBehavior

        def add_new_banner(collection_id:, uploaded_file_ids:)
          f = uploaded_files(uploaded_file_ids).first
          file_location = process_file_location(f)

          banner_info = CollectionBrandingInfo.new(
            collection_id:,
            filename: File.split(f.file_url).last,
            role: "banner",
            alt_txt: "",
            target_url: ""
          )
          banner_info.save file_location
        end
      end
    end
  end
end

Hyrax::Transactions::Steps::SaveCollectionBanner.prepend(Hyrax::Transactions::Steps::SaveCollectionBannerDecorator)
