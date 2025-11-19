# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to override to #sorted_users to account for multitenancy in Hyku

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
  end
end

Hyrax::UserStatImporter.prepend(Hyrax::UserStatImporterDecorator)
