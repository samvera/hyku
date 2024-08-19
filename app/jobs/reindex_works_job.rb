# frozen_string_literal: true

class ReindexWorksJob < ApplicationJob
  def perform(work = nil)
    if work.present?
      if work.is_a?(Valkyrie::Resource)
        Hyrax.index_adapter.save(resource: work)
      else
        work.update_index
      end
    else
      # previously this used models = Site.instance.available_works
      # however, this means that if we stop allowing a particular work
      # class for a tenant, we would also not ever reindex it.
      # It is safer to use all work classes.
      models = Hyrax::ModelRegistry.work_classes
      unique_models = []
      models.each do |model|
        unique_models << Wings::ModelRegistry.lookup(model)
      end
      unique_models.uniq.each do |model|
        works = Hyrax.query_service.find_all_of_model(model:)
        works.each do |w|
          ReindexItemJob.perform_later(w.id.to_s)
        end
      end
    end
  end
end
