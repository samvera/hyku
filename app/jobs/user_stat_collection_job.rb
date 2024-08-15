class UserStatCollectionJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    importer = Hyrax::UserStatImporter.new(verbose: true, logging: true)
    importer.import
    UserStatCollectionJob.set(wait_until: Date.tomorrow.midnight).perform_later
  end
end
