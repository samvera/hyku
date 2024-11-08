# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0 to save the collection banner in 'public/uploads' and include alttext

module Hyrax
  module Transactions
    module Steps
      module SaveCollectionBannerDecorator
        include Hyku::CollectionBrandingBehavior

        def call(collection_resource, update_banner_file_ids: nil, alttext: nil, banner_unchanged_indicator: true)
          return Success(collection_resource) if ActiveModel::Type::Boolean.new.cast(banner_unchanged_indicator)
          collection_id = collection_resource.id.to_s
          process_banner_input(collection_id:, update_banner_file_ids:, alttext:)
          Success(collection_resource)
        end

        def process_banner_input(collection_id:, update_banner_file_ids:, alttext:)
          if !update_banner_file_ids && !alttext
            remove_banner(collection_id:)
          elsif update_banner_file_ids
            remove_banner(collection_id:)
            add_new_banner(collection_id:, uploaded_file_ids: update_banner_file_ids, alttext:)
          elsif alttext
            CollectionBrandingInfo
              .where(collection_id:, role: "banner")
              .first.update_column(:alt_text, alttext) # rubocop:disable Rails/SkipsModelValidations
          end
        end

        def add_new_banner(collection_id:, uploaded_file_ids:, alttext:)
          f = uploaded_files(uploaded_file_ids).first
          file_location = process_file_location(f)

          banner_info = CollectionBrandingInfo.new(
            collection_id:,
            filename: File.split(f.file_url).last,
            role: "banner",
            alt_txt: alttext,
            target_url: ""
          )
          banner_info.save file_location
        end
      end
    end
  end
end

Hyrax::Transactions::Steps::SaveCollectionBanner.prepend(Hyrax::Transactions::Steps::SaveCollectionBannerDecorator)
