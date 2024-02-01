# frozen_string_literal: true

class ReindexAdminSetsJob < ApplicationJob
  def perform
    AdministrativeSet.find_each do |admin_set|
      ReindexItemJob.perform_later(admin_set)
    end
  end
end
