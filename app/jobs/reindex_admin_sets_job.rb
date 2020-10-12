# frozen_string_literal: true

class ReindexAdminSetsJob < ApplicationJob
  def perform
    AdminSet.find_each(&:update_index)
  end
end
