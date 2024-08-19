# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0 to save the collection logo in 'public/uploads'

module Hyrax
  module Transactions
    module Steps
      module SaveCollectionLogoDecorator
        include Hyku::CollectionBrandingBehavior

        def create_logo_info(collection_id:, uploaded_file_id:, alttext:, linkurl:)
          file = uploaded_files(uploaded_file_id)
          file_location = process_file_location(file)

          logo_info = CollectionBrandingInfo.new(
            collection_id:,
            filename: File.split(file.file_url).last,
            role: "logo",
            alt_txt: alttext,
            target_url: linkurl
          )
          logo_info.save file_location
          logo_info
        end
      end
    end
  end
end

Hyrax::Transactions::Steps::SaveCollectionLogo.prepend(Hyrax::Transactions::Steps::SaveCollectionLogoDecorator)
