# frozen_string_literal: true

if ActiveModel::Type::Boolean.new.cast(ENV.fetch("REPOSITORY_S3_STORAGE", false))
  require "shrine/storage/s3"
  require "valkyrie/storage/shrine"
  require "valkyrie/shrine/checksum/s3"
end

# rubocop:disable Metrics/BlockLength
Rails.application.config.after_initialize do
  # Add all concerns that are migrating from ActiveFedora here
  WINGS_CONCERNS ||= [AdminSet, Collection, Etd, GenericWork, Image, Oer].freeze

  WINGS_CONCERNS.each do |klass|
    Wings::ModelRegistry.register("#{klass}Resource".constantize, klass)
    # we register itself so we can pre-translate the class in Freyja instead of having to translate in each query_service
    Wings::ModelRegistry.register(klass, klass)
  end

  Wings::ModelRegistry.register(FileSet, FileSet)
  Wings::ModelRegistry.register(Hyrax::FileSet, FileSet)
  Wings::ModelRegistry.register(Hydra::PCDM::File, Hydra::PCDM::File)
  Wings::ModelRegistry.register(Hyrax::FileMetadata, Hydra::PCDM::File)

  unless Valkyrie::MetadataAdapter.adapters.include?(:freyja)
    Valkyrie::MetadataAdapter.register(
      Freyja::MetadataAdapter.new,
      :freyja
    )
  end

  Valkyrie.config.metadata_adapter = :freyja
  Hyrax.config.query_index_from_valkyrie = true
  Hyrax.config.index_adapter = if ActiveModel::Type::Boolean.new.cast(ENV.fetch("HYKU_USE_QUEUED_INDEX", false))
                                 :redis_queue
                               else
                                 :solr_index
                               end

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(base_path: Rails.root.join("storage", "files"), file_mover: FileUtils.method(:cp)),
    :disk
  )

  if ActiveModel::Type::Boolean.new.cast(ENV.fetch("REPOSITORY_S3_STORAGE", false))
    shrine_s3_options = {
      bucket: ENV.fetch("REPOSITORY_S3_BUCKET") { "nurax_pg#{Rails.env}" },
      region: ENV.fetch("REPOSITORY_S3_REGION", "us-east-1"),
      access_key_id: ENV["REPOSITORY_S3_ACCESS_KEY"],
      secret_access_key: ENV["REPOSITORY_S3_SECRET_KEY"]
    }

    if ENV["REPOSITORY_S3_ENDPOINT"].present?
      shrine_s3_options[:endpoint] = "http://#{ENV['REPOSITORY_S3_ENDPOINT']}:#{ENV.fetch('REPOSITORY_S3_PORT', 9000)}"
      shrine_s3_options[:force_path_style] = true
    end

    Valkyrie::StorageAdapter.register(
      Valkyrie::Storage::Shrine.new(Shrine::Storage::S3.new(**shrine_s3_options)),
      :repository_s3
    )

    Valkyrie.config.storage_adapter = :repository_s3
  else
    Valkyrie.config.storage_adapter = :disk
  end

  # load all the sql based custom queries
  [
    Hyrax::CustomQueries::Navigators::CollectionMembers,
    Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator,
    Hyrax::CustomQueries::Navigators::ParentCollectionsNavigator,
    Hyrax::CustomQueries::Navigators::ChildFileSetsNavigator,
    Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
    Hyrax::CustomQueries::Navigators::FindFiles,
    Hyrax::CustomQueries::FindAccessControl,
    Hyrax::CustomQueries::FindCollectionsByType,
    Hyrax::CustomQueries::FindFileMetadata,
    Hyrax::CustomQueries::FindIdsByModel,
    Hyrax::CustomQueries::FindManyByAlternateIds,
    Hyrax::CustomQueries::FindModelsByAccess,
    Hyrax::CustomQueries::FindCountBy,
    Hyrax::CustomQueries::FindByDateRange,
    Hyrax::CustomQueries::FindBySourceIdentifier,
    Hyrax::CustomQueries::FindByModelAndPropertyValue
  ].each do |handler|
    Hyrax.query_service.services[0].custom_queries.register_query_handler(handler)
  end

  [
    Wings::CustomQueries::FindBySourceIdentifier
  ].each do |handler|
    Hyrax.query_service.services[1].custom_queries.register_query_handler(handler)
  end
end

Rails.application.config.to_prepare do
  AdminSetResource.class_eval do
    attribute :internal_resource, Valkyrie::Types::Any.default("AdminSet"), internal: true
  end

  CollectionResource.class_eval do
    attribute :internal_resource, Valkyrie::Types::Any.default("Collection"), internal: true
  end

  Valkyrie.config.resource_class_resolver = lambda do |resource_klass_name|
    klass = resource_klass_name.gsub(/Resource$/, '').constantize
    Wings::ModelRegistry.reverse_lookup(klass) || klass
  end
end
# rubocop:enable Metrics/BlockLength
