# frozen_string_literal: true

class DestroySplitPagesJob < ApplicationJob
  queue_as :default

  # @param id [String] the split page work to destroy
  # @param user_key [String, nil] who the deletion is attributed to; defaults to the system user
  def perform(id, user_key = nil)
    work = nil
    begin
      work = Hyrax.query_service.find_by(id:)
    rescue Valkyrie::Persistence::ObjectNotFoundError
      return
    end

    return unless work.is_child

    user = (user_key && ::User.find_by_user_key(user_key)) || ::User.system_user
    Hyrax::Transactions::Container['work_resource.destroy']
      .with_step_args('work_resource.delete_all_file_sets' => { user: },
                      'work_resource.delete' => { user: })
      .call(work)
      .value!
  end
end
