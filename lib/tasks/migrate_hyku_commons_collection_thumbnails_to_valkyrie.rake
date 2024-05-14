# frozen_string_literal: true

namespace :hyku do
  desc 'migrate Hyku Commons collection thumbnails to Valkyrie'
  task migrate_hyku_commons_collection_thumbnails_to_valkyrie: :environment do
    in_each_account do
      Collection.find_each do |collection|
        # get collection solr document's thumbnail_path for each collection
        doc = collection.to_solr
        original_thumbnail_path = File.join(Rails.public_path, doc['thumbnail_path_ss'])

        next unless File.exist?(original_thumbnail_path)

        # save collection to make it a valkyrie resource
        collection.save
        collection_resource = Hyrax.query_service.find_by(id: collection.id)

        # make CollectionBrandingInfo object
        CollectionBrandingInfo.new(
          collection_id: collection_resource.id,
          filename: File.basename(original_thumbnail_path),
          role: "thumbnail",
          alt_txt: "",
          target_url: ""
        ).save(original_thumbnail_path)

        # update solr document
        Hyrax.index_adapter.save(resource: collection_resource)
      end
    end
  end
end
