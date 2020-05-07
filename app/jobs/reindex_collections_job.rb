class ReindexCollectionsJob < ActiveJob::Base
  def perform
    Collection.find_each do |collection|
      collection.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
      collection.update_index
    end
  end
end
