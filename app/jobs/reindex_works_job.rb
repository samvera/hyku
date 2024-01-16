# frozen_string_literal: true

class ReindexWorksJob < ApplicationJob
  def perform(work = nil)
    if work.present?
      work.update_index
    else
      Site.instance.available_works.each do |work_type|
        work_type.constantize.find_each do |w|
          ReindexItemJob.perform_later(w)
        end
      end
    end
  end
end
