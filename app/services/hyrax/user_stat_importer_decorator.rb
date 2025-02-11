# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.1 to use Hyrax.query_service to find the fileset instead of FileSet.find
#   Remove this if https://github.com/samvera/hyrax/pull/6992 gets merged and Hyrax is updated appropriately
#   Also override to #sorted_users to account for multitenancy in Hyku
module Hyrax
  module UserStatImporterDecorator
    UserRecord = Struct.new('UserRecord', :id, :user_key, :last_stats_update)

    # Returns an array of users of that tenant sorted by the date of their last stats update.
    # Users that have not been recently updated will be at the top of the array.
    def sorted_users
      users = []
      ::User.registered.for_repository.without_system_accounts.uniq.each do |user|
        users.push(UserRecord.new(user.id, user.user_key, date_since_last_cache(user)))
      end
      users.sort_by(&:last_stats_update)
    end

    private

    def process_files(stats, user, start_date)
      file_ids_for_user(user).each do |file_id|
        file = Hyrax.query_service.find_by(id: file_id)
        view_stats = extract_stats_for(object: file, from: FileViewStat, start_date: start_date, user: user)
        stats = tally_results(view_stats, :views, stats) if view_stats.present?
        delay
        dl_stats = extract_stats_for(object: file, from: FileDownloadStat, start_date: start_date, user: user)
        stats = tally_results(dl_stats, :downloads, stats) if dl_stats.present?
        delay
      end
    end
  end
end

Hyrax::UserStatImporter.prepend(Hyrax::UserStatImporterDecorator)
