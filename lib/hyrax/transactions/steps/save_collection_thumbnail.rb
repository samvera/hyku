# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # Adds thumbnail info via `ChangeSet`.
      #
      # During the update collection process this step is called to update the file
      # to be used as a the thumbnail for the collection.
      #
      class SaveCollectionThumbnail
        include Dry::Monads[:result]
        include Hyku::CollectionBrandingBehavior

        ##
        # @param [Hyrax::ChangeSet] change_set
        # @param [Array<Integer>] update_thumbnail_file_ids
        # @param [Boolean] thumbnail_unchanged_indicator
        #
        # @return [Dry::Monads::Result] `Failure` if the thumbnail info fails to save;
        #   `Success(input)`, otherwise.
        def call(collection_resource, update_thumbnail_file_ids: nil, thumbnail_unchanged_indicator: true, alttext_values: nil)
          collection_id = collection_resource.id.to_s
          process_thumbnail_input(collection_id:, update_thumbnail_file_ids:, thumbnail_unchanged_indicator:, alttext_values:)
          Success(collection_resource)
        end

        private

        def process_thumbnail_input(collection_id:, update_thumbnail_file_ids:, thumbnail_unchanged_indicator:, alttext_values:)
          if !update_thumbnail_file_ids && !alttext_values
            remove_thumbnail(collection_id:)
          elsif update_thumbnail_file_ids && thumbnail_unchanged_indicator.nil?
            remove_thumbnail(collection_id:)
            add_new_thumbnail(collection_id:, uploaded_file_ids: update_thumbnail_file_ids, alttext_values:)
          else
            CollectionBrandingInfo
              .where(collection_id:, role: 'thumbnail')
              .first
              .update_column(:alt_text, alttext_values.first) # rubocop:disable Rails/SkipsModelValidations
          end
        end

        def remove_thumbnail(collection_id:)
          thumbnail_info = CollectionBrandingInfo.where(collection_id:).where(role: "thumbnail")
          thumbnail_info&.delete_all
        end

        def add_new_thumbnail(collection_id:, uploaded_file_ids:, alttext_values:)
          file = uploaded_files(uploaded_file_ids).first
          file_location = process_file_location(file)

          thumbnail_info = CollectionBrandingInfo.new(
            collection_id:,
            filename: File.split(file.file_url).last,
            role: "thumbnail",
            alt_txt: alttext_values&.first || "",
            target_url: ""
          )
          thumbnail_info.save file_location
        end

        def uploaded_files(uploaded_file_ids)
          return [] if uploaded_file_ids.empty?
          UploadedFile.find(uploaded_file_ids)
        end
      end
    end
  end
end
