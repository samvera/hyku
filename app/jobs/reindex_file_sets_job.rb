# frozen_string_literal: true

class ReindexFileSetsJob < ApplicationJob
  def perform
    models = Hyrax::ModelRegistry.file_set_classes
    unique_models = []
    models.each do |model|
      unique_models << Wings::ModelRegistry.lookup(model)
    end

    unique_models.uniq.each do |model|
      file_sets = Hyrax.query_service.find_all_of_model(model:)
      file_sets.each do |fs|
        ReindexItemJob.perform_later(fs.id.to_s)
      end
    end
  end
end
