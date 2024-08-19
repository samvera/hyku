# frozen_string_literal: true

class ReindexAdminSetsJob < ApplicationJob
  def perform
    models = Hyrax::ModelRegistry.admin_set_classes
    unique_models = []
    models.each do |model|
      unique_models << Wings::ModelRegistry.lookup(model)
    end

    unique_models.uniq.each do |model|
      admin_sets = Hyrax.query_service.find_all_of_model(model:)
      admin_sets.each do |as|
        ReindexItemJob.perform_later(as.id.to_s)
      end
    end
  end
end
