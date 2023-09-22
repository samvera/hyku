# frozen_string_literal: true

class ReindexCollectionsJob < ApplicationJob
  def perform
    Collection.find_each do |collection|
      ReindexItemJob.perform_later(collection)
    end
  end
end
