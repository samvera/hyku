class ReindexWorksJob < ActiveJob::Base
  def perform
    Hyrax.config.registered_curation_concern_types.each do |work_type|
      work_type.constantize.find_each do |work|
        work.update_index
      end
    end
  end
end
