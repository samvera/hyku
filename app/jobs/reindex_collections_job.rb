# frozen_string_literal: true

class ReindexCollectionsJob < ApplicationJob
  def perform
    models = Hyrax::ModelRegistry.collection_classes
    unique_models = []
    models.each do |model|
      unique_models << Wings::ModelRegistry.lookup(model)
    end

    unique_models.uniq.each do |model|
      collections = Hyrax.query_service.find_all_of_model(model:)
      collections.each do |coll|
        ReindexItemJob.perform_later(coll.id.to_s)
      end
    end
  end
end
