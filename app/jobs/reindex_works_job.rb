# frozen_string_literal: true

class ReindexWorksJob < ApplicationJob
  def perform
    Site.instance.available_works.each do |work_type|
      work_type.constantize.find_each do |work|
        ReindexItemJob.perform_later(work)
      end
    end
  end
end
