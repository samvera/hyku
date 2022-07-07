# frozen_string_literal: true

class ReindexCollectionsJob < ApplicationJob
  def perform
    Collection.find_each do |collection|
      collection.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
      collection.update_index
    end
  end
end
