# frozen_string_literal: true

class DestroySplitPagesJob < ApplicationJob
  queue_as :default

  def perform(id)
    work = nil
    begin
      work = Hyrax.query_service.find_by(id:)
    rescue Valkyrie::Persistence::ObjectNotFoundError
      return
    end

    return unless work.is_child

    # Does this work?
    transaction = Hyrax::Transactions::WorkDestroy.new
    transaction.call(work)
  end
end
