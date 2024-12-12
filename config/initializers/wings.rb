# frozen_string_literal: true
# rubocop:disable Metrics/BlockLength
Rails.application.config.after_initialize do
  [
    GenericWork,
    Image,
    Etd,
    Oer
  ].each do |klass|
    Wings::ModelRegistry.register("#{klass}Resource".constantize, klass)
    # we register itself so we can pre-translate the class in Freyja instead of having to translate in each query_service
    Wings::ModelRegistry.register(klass, klass)
  end
  Wings::ModelRegistry.register(Collection, Collection)
  Wings::ModelRegistry.register(CollectionResource, Collection)
  Wings::ModelRegistry.register(AdminSet, AdminSet)
  Wings::ModelRegistry.register(AdminSetResource, AdminSet)
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
  Hyrax.config.index_adapter = :solr_index

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(base_path: Rails.root.join("storage", "files"),
                                file_mover: FileUtils.method(:cp)),
    :disk
  )
  Valkyrie.config.storage_adapter  = :disk
  Valkyrie.config.indexing_adapter = :solr_index
  # TODO move these to bulkrax somehow
  Hyrax.query_service.services[0].custom_queries.register_query_handler(Hyrax::CustomQueries::FindBySourceIdentifier)
  Hyrax.query_service.services[1].custom_queries.register_query_handler(Wings::CustomQueries::FindBySourceIdentifier)
end

Rails.application.config.to_prepare do
  AdminSetResource.class_eval do
    attribute :internal_resource, Valkyrie::Types::Any.default("AdminSet"), internal: true
  end

  CollectionResource.class_eval do
    attribute :internal_resource, Valkyrie::Types::Any.default("Collection"), internal: true
  end
end
# rubocop:enable Metrics/BlockLength
