# frozen_string_literal: true

class ReindexItemJob < ApplicationJob
  def perform(item_id)
    item = Hyrax.query_service.find_by(id: item_id)

    if item.is_a?(Valkyrie::Resource)
      Hyrax.index_adapter.save(resource: item)
    else
      item.update_index
    end
  end
end
