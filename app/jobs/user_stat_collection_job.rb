# frozen_string_literal: true
class UserStatCollectionJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    return unless Hyrax.config.analytics_reporting?

    # Rails 7.2: Disable verbose logging to avoid broadcast logger issues
    importer = Hyrax::UserStatImporter.new(verbose: false, logging: true)
    importer.import
    UserStatCollectionJob.set(wait_until: Date.tomorrow.midnight).perform_later
  end
end
