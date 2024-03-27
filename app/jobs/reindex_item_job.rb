# frozen_string_literal: true

class ReindexItemJob < ApplicationJob
  def perform(item)
    if item.is_a?(Valkyrie::Resource)
      Hyrax.index_adapter.save(resource: item)
    else
      item.update_index
    end
  end
end
