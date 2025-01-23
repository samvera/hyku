# frozen_string_literal: true
class UserStatCollectionJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    return unless UserStat.exists?

    importer = Hyrax::UserStatImporter.new(verbose: true, logging: true)
    importer.import
    UserStatCollectionJob.set(wait_until: Date.tomorrow.midnight).perform_later
  end
end
