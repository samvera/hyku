# frozen_string_literal: true

class ReindexItemJob < ApplicationJob
  def perform(item)
    Hyrax.index_adapter.save(resource: item)
  end
end
