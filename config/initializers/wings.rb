# frozen_string_literal: true

if ActiveModel::Type::Boolean.new.cast(ENV.fetch("REPOSITORY_S3_STORAGE", false))
  require "shrine/storage/s3"
  require "valkyrie/storage/shrine"
  require "valkyrie/shrine/checksum/s3"
end

# Register the Postgres metadata adapter early so that any code autoloaded
# during to_prepare (e.g. decorator files that reference Hyrax::SolrQueryService)
# can resolve Valkyrie.config.metadata_adapter without hitting nil.
# When Wings is active the after_initialize block below replaces this with :freyja.
unless Valkyrie::MetadataAdapter.adapters.include?(:pg_metadata)
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Postgres::MetadataAdapter.new,
    :pg_metadata
  )
end

Valkyrie.config.metadata_adapter = :pg_metadata

# rubocop:disable Metrics/BlockLength
Rails.application.config.after_initialize do
  if Hyrax.config.disable_wings
    # Postgres adapter already registered and active; nothing more to do for
    # the metadata adapter.
  else
    require 'wings'
    require 'freyja'

    WINGS_CONCERNS ||= [AdminSet, Collection, Etd, GenericWork, Image, Oer].freeze

    WINGS_CONCERNS.each do |klass|
      Wings::ModelRegistry.register("#{klass}Resource".constantize, klass)
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

    # Register lazy migration from legacy ActiveFedora models to Valkyrie resources.
    # Done here (after config load) so we can use Hyrax.config.disable_wings.
    AdminSetResource.class_eval { Hyrax::ValkyrieLazyMigration.migrating(self, from: ::AdminSet) }
    CollectionResource.class_eval { Hyrax::ValkyrieLazyMigration.migrating(self, from: ::Collection) }
    GenericWorkResource.class_eval { Hyrax::ValkyrieLazyMigration.migrating(self, from: GenericWork) }
    EtdResource.class_eval { Hyrax::ValkyrieLazyMigration.migrating(self, from: Etd) }
    ImageResource.class_eval { Hyrax::ValkyrieLazyMigration.migrating(self, from: Image) }
    OerResource.class_eval { Hyrax::ValkyrieLazyMigration.migrating(self, from: Oer) }
    Hyrax::ValkyrieLazyMigration.migrating(Hyrax::FileSet, from: ::FileSet)
  end

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

  custom_query_handlers = [
    Hyrax::CustomQueries::Navigators::CollectionMembers,
    Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator,
    Hyrax::CustomQueries::Navigators::ParentCollectionsNavigator,
    Hyrax::CustomQueries::Navigators::ParentWorkNavigator,
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
  ]

  if Hyrax.config.disable_wings
    # Postgres query service registers custom queries directly
    custom_query_handlers.each do |handler|
      Hyrax.query_service.custom_queries.register_query_handler(handler)
    end
  else
    custom_query_handlers.each do |handler|
      Hyrax.query_service.services[0].custom_queries.register_query_handler(handler)
    end

    [
      Wings::CustomQueries::FindBySourceIdentifier
    ].each do |handler|
      Hyrax.query_service.services[1].custom_queries.register_query_handler(handler)
    end
  end
end

LEGACY_TO_VALKYRIE = {
  'AdminSet' => 'AdminSetResource',
  'Collection' => 'CollectionResource',
  'GenericWork' => 'GenericWorkResource',
  'Image' => 'ImageResource',
  'Etd' => 'EtdResource',
  'Oer' => 'OerResource',
  'FileSet' => 'Hyrax::FileSet'
}.freeze

VALKYRIE_MODEL_NAME_MAP = {
  'AdminSetResource' => { legacy_name: 'AdminSet',   route_namespace: 'admin' },
  'CollectionResource' => { legacy_name: 'Collection', route_namespace: nil },
  'GenericWorkResource' => { legacy_name: 'GenericWork', route_namespace: nil },
  'ImageResource' => { legacy_name: 'Image',      route_namespace: nil },
  'EtdResource' => { legacy_name: 'Etd',        route_namespace: nil },
  'OerResource' => { legacy_name: 'Oer',        route_namespace: nil }
}.freeze

Rails.application.config.to_prepare do
  unless Hyrax.config.disable_wings
    AdminSetResource.class_eval do
      attribute :internal_resource, Valkyrie::Types::Any.default("AdminSet"), internal: true
    end

    CollectionResource.class_eval do
      attribute :internal_resource, Valkyrie::Types::Any.default("Collection"), internal: true
    end
  end

  if Hyrax.config.disable_wings
    [AdminSetResource, CollectionResource, GenericWorkResource, ImageResource,
     EtdResource, OerResource].each do |klass|
      legacy_name = VALKYRIE_MODEL_NAME_MAP[klass.name][:legacy_name]
      klass.define_singleton_method(:to_rdf_representation) { legacy_name }
    end

    Hyrax::FileSet.define_singleton_method(:to_rdf_representation) { 'FileSet' }

    [AdminSetResource, CollectionResource, GenericWorkResource, ImageResource,
     EtdResource, OerResource].each do |klass|
      legacy_name = VALKYRIE_MODEL_NAME_MAP[klass.name][:legacy_name]
      legacy_klass = legacy_name.constantize
      mn = legacy_klass.model_name
      klass.define_singleton_method(:model_name) do
        @_valkyrie_model_name ||= begin
          name = ActiveModel::Name.new(klass, nil, legacy_name)
          name.instance_variable_set(:@klass, klass)
          name.instance_variable_set(:@name, klass.name)
          name.instance_variable_set(:@route_key, mn.route_key)
          name.instance_variable_set(:@singular_route_key, mn.singular_route_key)
          name.instance_variable_set(:@human, legacy_name.underscore.humanize.titleize)
          name.define_singleton_method(:klass) { klass }
          name
        end
      end
    end

    Valkyrie.config.resource_class_resolver = lambda do |resource_klass_name|
      mapped = LEGACY_TO_VALKYRIE[resource_klass_name]
      (mapped || resource_klass_name).constantize
    end
  else
    Valkyrie.config.resource_class_resolver = lambda do |resource_klass_name|
      klass = resource_klass_name.gsub(/Resource$/, '').constantize
      Wings::ModelRegistry.reverse_lookup(klass) || klass
    end
  end
end
# rubocop:enable Metrics/BlockLength
