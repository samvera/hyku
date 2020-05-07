class ReindexAdminSetsJob < ActiveJob::Base
  def perform
    AdminSet.find_each do |admin_set|
      admin_set.update_index
    end
  end
end
