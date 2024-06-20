# frozen_string_literal: true

class ReindexItemJob < ApplicationJob
  def perform(item)
    item.responds_to?(:update_index) ? item.update_index : ActiveFedora::Base.find(item).update_index
  end
end
