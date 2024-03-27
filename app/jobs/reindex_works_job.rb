# frozen_string_literal: true

class ReindexWorksJob < ApplicationJob
  def perform(work = nil)
    if work.present?
      if work.is_a?(Valkyrie::Resource)
        Hyrax.index_adapter.save(resource: work)
      else
        work.update_index
      end
    else
      Site.instance.available_works.each do |work_type|
        work_type.constantize.find_each do |w|
          ReindexItemJob.perform_later(w)
        end
      end
    end
  end
end
