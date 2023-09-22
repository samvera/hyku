# frozen_string_literal: true

class ReindexItemJob < ApplicationJob
  def perform(item)
    item.update_index
  end
end
