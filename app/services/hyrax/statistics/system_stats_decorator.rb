# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0: list only this tenant's users. Users are shared across
# tenants, so Hyrax's ::User query showed every tenant's newest users on Reports.
module Hyrax
  module Statistics
    module SystemStatsDecorator
      def recent_users
        users = ::User.where(id: ::User.for_repository.select(:id)).without_system_accounts
        return users.order(created_at: :desc).limit(limit) if start_date.blank?

        users.where(created_at: start_date..(end_date || DateTime.current))
      end
    end
  end
end

Hyrax::Statistics::SystemStats.prepend(Hyrax::Statistics::SystemStatsDecorator)
