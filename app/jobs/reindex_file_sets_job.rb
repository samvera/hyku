# frozen_string_literal: true

class ReindexFileSetsJob < ApplicationJob
  def perform
    FileSet.find_each do |file_set|
      ReindexItemJob.perform_later(file_set)
    end
  end
end
